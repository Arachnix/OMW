import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/omw_models.dart';
import 'api_config.dart';

/// Error returned by the backend (`{ success: false, error }`) or a network
/// failure.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  final String message;
  final int? statusCode;
  final bool isNetwork;

  @override
  String toString() => message;
}

class LoginResult {
  const LoginResult(this.user, this.wallet);
  final OmwUser user;
  final Wallet wallet;
}

class PurchaseResult {
  const PurchaseResult({
    required this.tokens,
    required this.newAvailable,
    required this.transactionId,
  });
  final int tokens;
  final int newAvailable;
  final String transactionId;
}

class CancelResult {
  const CancelResult(this.task, {required this.refunded, required this.fee});
  final OmwTask task;
  final int refunded;
  final int fee;
}

/// Everything the app needs from the backend. [HttpOmwApi] talks to the real
/// server; tests supply a fake.
abstract class OmwApi {
  Future<LoginResult> login({required String regNumber, required String name});
  Future<OmwUser> profile(String userId);
  Future<Wallet> wallet(String userId);
  Future<List<WalletTx>> transactions(String userId);
  Future<List<CampusLocation>> locations();
  Future<RouteEstimate> route(
    String pickupId,
    String dropId, {
    String? originId,
  });
  Future<int> suggestWager(String pickupId, String dropId);
  Future<List<OmwTask>> tasks({double? lat, double? lng, double? heading});
  Future<OmwTask> task(String id);
  Future<OmwTask> createTask({
    required String requesterId,
    required String title,
    required String category,
    required String pickupId,
    required String dropId,
    required int wager,
    required String notes,
  });
  Future<OmwTask> claim(String taskId, String runnerId);
  Future<OmwTask> verifyPickup(String taskId, String otp);
  Future<OmwTask> verifyDelivery(String taskId, String otp);
  Future<OmwTask> surge(String taskId, int tokens);
  Future<CancelResult> cancel(String taskId, {String? reason});
  Future<OmwTask> drop(String taskId, String runnerId, String reason);
  Future<PurchaseResult> buyTokens(String userId, int tokens);
  Future<int> withdraw(String userId, int tokens, String upi);

  /// Live events from the WebSocket hub.
  Stream<LiveEvent> events();
  void sendRunnerLocation(String runnerId, double lat, double lng);
  void sendRunnerArrived(String taskId, String runnerId);
  void dispose();
}

/// A message pushed by the backend WebSocket (src/services/socket).
class LiveEvent {
  const LiveEvent(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;

  OmwTask? get task => data['task'] is Map<String, dynamic>
      ? OmwTask.fromJson(data['task'] as Map<String, dynamic>)
      : null;
  String? get taskId => data['taskId'] as String?;
  String? get actorId => data['actorId'] as String?;
  String? get runnerId => data['runnerId'] as String?;
}

class HttpOmwApi implements OmwApi {
  HttpOmwApi({String? baseUrl, http.Client? client})
    : _base = baseUrl ?? ApiConfig.baseUrl,
      _client = client ?? http.Client();

  final String _base;
  final http.Client _client;
  static const _timeout = Duration(seconds: 10);

  WebSocketChannel? _socket;
  StreamController<LiveEvent>? _events;
  Timer? _reconnect;
  bool _disposed = false;

  // HTTP -------------------------------------------------------------------

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    http.Response res;
    try {
      final headers = {'Content-Type': 'application/json'};
      res =
          await (method == 'GET'
                  ? _client.get(uri, headers: headers)
                  : _client.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(body ?? {}),
                    ))
              .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'The OMW server took too long to respond.',
        isNetwork: true,
      );
    } catch (_) {
      throw const ApiException(
        'Can\'t reach the OMW server. Check your connection.',
        isNetwork: true,
      );
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected response from the server (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode >= 400 || json['success'] == false) {
      throw ApiException(
        (json['error'] as String?) ?? 'Request failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    return json;
  }

  OmwTask _task(Map<String, dynamic> j) =>
      OmwTask.fromJson(j['task'] as Map<String, dynamic>);

  @override
  Future<LoginResult> login({
    required String regNumber,
    required String name,
  }) async {
    final j = await _send(
      'POST',
      '/api/auth/login',
      body: {'regNumber': regNumber, 'name': name},
    );
    return LoginResult(
      OmwUser.fromJson(j['user'] as Map<String, dynamic>),
      Wallet.fromJson(j['wallet'] as Map<String, dynamic>),
    );
  }

  @override
  Future<OmwUser> profile(String userId) async {
    final j = await _send('GET', '/api/users/$userId');
    return OmwUser.fromJson(j['profile'] as Map<String, dynamic>);
  }

  @override
  Future<Wallet> wallet(String userId) async {
    final j = await _send(
      'GET',
      '/api/wallet/balance',
      query: {'userId': userId},
    );
    return Wallet.fromJson(j['wallet'] as Map<String, dynamic>);
  }

  @override
  Future<List<WalletTx>> transactions(String userId) async {
    final j = await _send(
      'GET',
      '/api/wallet/transactions',
      query: {'userId': userId, 'limit': '100'},
    );
    return [
      for (final t in j['transactions'] as List)
        WalletTx.fromJson(t as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CampusLocation>> locations() async {
    final j = await _send('GET', '/api/map/locations');
    return [
      for (final l in j['locations'] as List)
        CampusLocation.fromJson(l as Map<String, dynamic>),
    ];
  }

  @override
  Future<RouteEstimate> route(
    String pickupId,
    String dropId, {
    String? originId,
  }) async {
    final j = await _send(
      'POST',
      '/api/map/route-calculate',
      body: {
        'pickupNodeId': pickupId,
        'dropNodeId': dropId,
        'runnerOriginNodeId': ?originId,
      },
    );
    return RouteEstimate.fromJson(j);
  }

  @override
  Future<int> suggestWager(String pickupId, String dropId) async {
    final j = await _send(
      'POST',
      '/api/tasks/calculate-wager',
      body: {'pickupNodeId': pickupId, 'dropNodeId': dropId},
    );
    return ((j['calculation'] as Map)['recommendedWager'] as num).round();
  }

  @override
  Future<List<OmwTask>> tasks({
    double? lat,
    double? lng,
    double? heading,
  }) async {
    final j = await _send(
      'GET',
      '/api/tasks',
      query: {
        if (lat != null) 'runnerLat': '$lat',
        if (lng != null) 'runnerLng': '$lng',
        if (heading != null) 'heading': '$heading',
      },
    );
    return [
      for (final t in j['tasks'] as List)
        OmwTask.fromJson(t as Map<String, dynamic>),
    ];
  }

  @override
  Future<OmwTask> task(String id) async =>
      _task(await _send('GET', '/api/tasks/$id'));

  @override
  Future<OmwTask> createTask({
    required String requesterId,
    required String title,
    required String category,
    required String pickupId,
    required String dropId,
    required int wager,
    required String notes,
  }) async => _task(
    await _send(
      'POST',
      '/api/tasks',
      body: {
        'requesterId': requesterId,
        'title': title,
        'category': category,
        'pickupNodeId': pickupId,
        'dropNodeId': dropId,
        'wager': wager,
        'notes': notes,
      },
    ),
  );

  @override
  Future<OmwTask> claim(String taskId, String runnerId) async => _task(
    await _send(
      'POST',
      '/api/tasks/$taskId/claim',
      body: {'runnerId': runnerId},
    ),
  );

  @override
  Future<OmwTask> verifyPickup(String taskId, String otp) async => _task(
    await _send('POST', '/api/tasks/$taskId/verify-pickup', body: {'otp': otp}),
  );

  @override
  Future<OmwTask> verifyDelivery(String taskId, String otp) async => _task(
    await _send(
      'POST',
      '/api/tasks/$taskId/verify-delivery',
      body: {'otp': otp},
    ),
  );

  @override
  Future<OmwTask> surge(String taskId, int tokens) async => _task(
    await _send(
      'POST',
      '/api/tasks/$taskId/surge',
      body: {'surgeTokens': tokens},
    ),
  );

  @override
  Future<CancelResult> cancel(String taskId, {String? reason}) async {
    final j = await _send(
      'POST',
      '/api/tasks/$taskId/cancel',
      body: {'reason': reason},
    );
    final refund = (j['refund'] as Map?) ?? const {};
    return CancelResult(
      _task(j),
      refunded: (refund['refundedTokens'] as num?)?.round() ?? 0,
      fee: (refund['feeCharged'] as num?)?.round() ?? 0,
    );
  }

  @override
  Future<OmwTask> drop(String taskId, String runnerId, String reason) async =>
      _task(
        await _send(
          'POST',
          '/api/tasks/$taskId/drop',
          body: {'runnerId': runnerId, 'reason': reason},
        ),
      );

  @override
  Future<PurchaseResult> buyTokens(String userId, int tokens) async {
    final order = await _send(
      'POST',
      '/api/payments/create-order',
      body: {'tokenAmount': tokens, 'userId': userId},
    );
    final orderId = (order['order'] as Map)['orderId'] as String;
    // Razorpay test network: the backend accepts its sandbox signature, so no
    // real money moves.
    final j = await _send(
      'POST',
      '/api/payments/verify-payment',
      body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': 'pay_${DateTime.now().millisecondsSinceEpoch}',
        'razorpay_signature': 'test_mock_signature',
        'tokenAmount': tokens,
        'userId': userId,
      },
    );
    return PurchaseResult(
      tokens: (j['creditedTokens'] as num).round(),
      newAvailable: (j['newAvailableBalance'] as num).round(),
      transactionId: j['transactionId'] as String,
    );
  }

  @override
  Future<int> withdraw(String userId, int tokens, String upi) async {
    final j = await _send(
      'POST',
      '/api/wallet/withdraw',
      body: {
        'userId': userId,
        'tokens': tokens,
        'method': 'UPI',
        'destination': upi,
      },
    );
    return (j['remainingTokens'] as num).round();
  }

  // WebSocket ----------------------------------------------------------------

  @override
  Stream<LiveEvent> events() {
    _events ??= StreamController<LiveEvent>.broadcast(onListen: _connect);
    return _events!.stream;
  }

  void _connect() {
    if (_disposed || _socket != null) return;
    try {
      final socket = WebSocketChannel.connect(ApiConfig.socketUrl);
      _socket = socket;
      socket.stream.listen(
        (raw) {
          try {
            final j = jsonDecode('$raw') as Map<String, dynamic>;
            final data = j['data'];
            _events?.add(
              LiveEvent(
                j['type'] as String? ?? '',
                data is Map<String, dynamic> ? data : const {},
              ),
            );
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _socket = null;
    if (_disposed) return;
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 3), _connect);
  }

  void _sendJson(Map<String, Object?> msg) {
    try {
      _socket?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  @override
  void sendRunnerLocation(String runnerId, double lat, double lng) =>
      _sendJson({
        'type': 'RUNNER_LOCATION_UPDATE',
        'runnerId': runnerId,
        'lat': lat,
        'lng': lng,
      });

  @override
  void sendRunnerArrived(String taskId, String runnerId) => _sendJson({
    'type': 'RUNNER_ARRIVED',
    'taskId': taskId,
    'runnerId': runnerId,
  });

  @override
  void dispose() {
    _disposed = true;
    _reconnect?.cancel();
    _socket?.sink.close();
    _events?.close();
    _client.close();
  }
}
