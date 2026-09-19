import 'dart:async';

import 'package:omw_delivery/api/omw_api.dart';
import 'package:omw_delivery/models/omw_models.dart';

/// In-memory stand-in for the OMW backend, mirroring its rules closely
/// enough for widget tests (escrow, stake, OTP checks).
class FakeOmwApi implements OmwApi {
  FakeOmwApi({this.available = 85, this.failTasks = false});

  int available;
  int escrow = 0;
  int staked = 0;
  bool failTasks;
  final events$ = StreamController<LiveEvent>.broadcast();
  final List<Map<String, Object?>> sent = [];
  final Map<String, Map<String, dynamic>> _tasks = {};
  final List<WalletTx> _txs = [];
  int _seq = 100;

  static const me = 'usr-me';
  static const other = 'usr-other';

  static final _locations = [
    const CampusLocation(
      id: 'loc-foody-st',
      name: 'Foody Street Campus Boulevard',
      category: 'food',
      lat: 12.9707,
      lng: 79.1608,
    ),
    const CampusLocation(
      id: 'loc-q-block',
      name: "Q Block Men's Residential Tower",
      category: 'hostel',
      lat: 12.9726,
      lng: 79.1624,
    ),
    const CampusLocation(
      id: 'loc-sjt',
      name: 'Silver Jubilee Tower (SJT)',
      category: 'academic',
      lat: 12.9710,
      lng: 79.1635,
    ),
    const CampusLocation(
      id: 'loc-gazebo',
      name: 'Gazebo Food Court & Juice Bar',
      category: 'food',
      lat: 12.9705,
      lng: 79.1601,
    ),
    const CampusLocation(
      id: 'loc-p-block',
      name: "P Block Men's Hostel",
      category: 'hostel',
      lat: 12.9718,
      lng: 79.1619,
    ),
  ];

  CampusLocation _loc(String id) => _locations.firstWhere((l) => l.id == id);

  /// Adds an open task from another student (shows on the courier feed).
  OmwTask seedOpenTask({
    String pickup = 'loc-gazebo',
    String drop = 'loc-p-block',
    int wager = 30,
  }) {
    final id = 'TSK-${_seq++}';
    final p = _loc(pickup), d = _loc(drop);
    _tasks[id] = {
      'id': id,
      'title': 'Small Box delivery',
      'category': 'small',
      'requesterId': other,
      'requesterName': 'Rohit Verma',
      'requesterTrustScore': 4.9,
      'pickupNodeId': p.id,
      'pickupNodeName': p.name,
      'pickupCoords': [p.lat, p.lng],
      'dropNodeId': d.id,
      'dropNodeName': d.name,
      'dropCoords': [d.lat, d.lng],
      'wager': wager,
      'notes': '',
      'urgency': 'normal',
      'status': 'OPEN',
      'pickupOtp': '1111',
      'deliveryOtp': '2222',
      'createdAt': DateTime.now().toIso8601String(),
    };
    return OmwTask.fromJson(_tasks[id]!);
  }

  /// Simulates another runner acting on one of my tasks.
  void pushStatus(String id, String status, {String runner = 'Marcus Vance'}) {
    final t = _tasks[id]!;
    t['status'] = status;
    t['runnerId'] = other;
    t['runnerName'] = runner;
    events$.add(
      LiveEvent('TASK_STATE_CHANGED', {
        'taskId': id,
        'status': status,
        'task': Map<String, dynamic>.from(t),
        'actorId': other,
      }),
    );
  }

  Wallet get _wallet =>
      Wallet(available: available, escrow: escrow, staked: staked);

  @override
  Future<LoginResult> login({
    required String regNumber,
    required String name,
  }) async => LoginResult(
    OmwUser(
      id: me,
      name: name,
      regNumber: regNumber,
      hostelBlock: 'Q Block',
      trustScore: 4.8,
      completedTasks: 28,
      isRestricted: false,
    ),
    _wallet,
  );

  @override
  Future<OmwUser> profile(String userId) async => OmwUser(
    id: me,
    name: 'Vismay Shrouty',
    regNumber: 'vismay@vit.ac.in',
    hostelBlock: 'Q Block',
    trustScore: 4.8,
    completedTasks: 28,
    isRestricted: false,
  );

  @override
  Future<Wallet> wallet(String userId) async => _wallet;

  @override
  Future<List<WalletTx>> transactions(String userId) async => List.of(_txs);

  @override
  Future<List<CampusLocation>> locations() async => _locations;

  @override
  Future<RouteEstimate> route(
    String pickupId,
    String dropId, {
    String? originId,
  }) async => const RouteEstimate(
    distanceMeters: 400,
    walkMinutes: 6,
    queueMinutes: 2,
    detourMeters: 0,
  );

  @override
  Future<int> suggestWager(String pickupId, String dropId) async => 20;

  @override
  Future<List<OmwTask>> tasks({
    double? lat,
    double? lng,
    double? heading,
  }) async {
    if (failTasks) {
      throw const ApiException('Can\'t reach the OMW server.', isNetwork: true);
    }
    return [for (final t in _tasks.values) OmwTask.fromJson(t)];
  }

  @override
  Future<OmwTask> task(String id) async => OmwTask.fromJson(_tasks[id]!);

  @override
  Future<OmwTask> createTask({
    required String requesterId,
    required String title,
    required String category,
    required String pickupId,
    required String dropId,
    required int wager,
    required String notes,
  }) async {
    if (available < wager) {
      throw ApiException(
        'Insufficient tokens. Available: $available, Required: $wager',
      );
    }
    available -= wager;
    escrow += wager;
    final id = 'TSK-${_seq++}';
    final p = _loc(pickupId), d = _loc(dropId);
    _tasks[id] = {
      'id': id,
      'title': title,
      'category': category,
      'requesterId': requesterId,
      'requesterName': 'Me',
      'requesterTrustScore': 4.8,
      'pickupNodeId': p.id,
      'pickupNodeName': p.name,
      'pickupCoords': [p.lat, p.lng],
      'dropNodeId': d.id,
      'dropNodeName': d.name,
      'dropCoords': [d.lat, d.lng],
      'wager': wager,
      'notes': notes,
      'urgency': 'normal',
      'status': 'OPEN',
      'pickupOtp': '3159',
      'deliveryOtp': '5942',
      'createdAt': DateTime.now().toIso8601String(),
    };
    return OmwTask.fromJson(_tasks[id]!);
  }

  @override
  Future<OmwTask> claim(String taskId, String runnerId) async {
    final t = _tasks[taskId]!;
    if (t['status'] != 'OPEN')
      throw const ApiException('Task cannot be claimed.');
    final stake = ((t['wager'] as int) * 0.25).round().clamp(2, 1 << 30);
    available -= stake;
    staked += stake;
    t
      ..['status'] = 'CLAIMED'
      ..['runnerId'] = runnerId
      ..['runnerName'] = 'Me Runner'
      ..['runnerStakeLocked'] = stake
      ..['claimedAt'] = DateTime.now().toIso8601String();
    return OmwTask.fromJson(t);
  }

  @override
  Future<OmwTask> verifyPickup(String taskId, String otp) async {
    final t = _tasks[taskId]!;
    if (t['pickupOtp'] != otp) throw const ApiException('Invalid Pickup OTP.');
    t['status'] = 'IN_TRANSIT';
    return OmwTask.fromJson(t);
  }

  @override
  Future<OmwTask> verifyDelivery(String taskId, String otp) async {
    final t = _tasks[taskId]!;
    if (t['deliveryOtp'] != otp) {
      throw const ApiException('Invalid Delivery OTP provided by recipient');
    }
    t['status'] = 'DELIVERED';
    available += (t['wager'] as int) + ((t['runnerStakeLocked'] as int?) ?? 0);
    staked = 0;
    return OmwTask.fromJson(t);
  }

  @override
  Future<OmwTask> surge(String taskId, int tokens) async {
    final t = _tasks[taskId]!;
    available -= tokens;
    escrow += tokens;
    t['wager'] = (t['wager'] as int) + tokens;
    return OmwTask.fromJson(t);
  }

  @override
  Future<CancelResult> cancel(String taskId, {String? reason}) async {
    final t = _tasks[taskId]!;
    final fee = t['status'] == 'CLAIMED' ? 5 : 0;
    final w = t['wager'] as int;
    escrow -= w;
    available += w - fee;
    t['status'] = 'CANCELLED';
    return CancelResult(OmwTask.fromJson(t), refunded: w - fee, fee: fee);
  }

  @override
  Future<OmwTask> drop(String taskId, String runnerId, String reason) async {
    final t = _tasks[taskId]!;
    staked -= (t['runnerStakeLocked'] as int?) ?? 0;
    t
      ..['status'] = 'OPEN'
      ..['runnerId'] = null
      ..['runnerName'] = null
      ..['dropReason'] = reason;
    return OmwTask.fromJson(t);
  }

  @override
  Future<PurchaseResult> buyTokens(String userId, int tokens) async {
    available += tokens;
    _txs.insert(
      0,
      WalletTx(
        id: 'tx-${_seq++}',
        type: TxType.purchase,
        tokens: tokens,
        reference: 'Razorpay',
        timestamp: DateTime.now(),
      ),
    );
    return PurchaseResult(
      tokens: tokens,
      newAvailable: available,
      transactionId: 'OMW2847293',
    );
  }

  @override
  Future<int> withdraw(String userId, int tokens, String upi) async {
    if (tokens > available)
      throw const ApiException('Insufficient tokens for withdrawal.');
    available -= tokens;
    return available;
  }

  @override
  Stream<LiveEvent> events() => events$.stream;

  @override
  void sendRunnerLocation(String runnerId, double lat, double lng) =>
      sent.add({'type': 'RUNNER_LOCATION_UPDATE', 'runnerId': runnerId});

  @override
  void sendRunnerArrived(String taskId, String runnerId) =>
      sent.add({'type': 'RUNNER_ARRIVED', 'taskId': taskId});

  @override
  void dispose() => events$.close();
}
