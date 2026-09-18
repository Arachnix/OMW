import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/order_model.dart';

class AppState extends ChangeNotifier {
  AppMode _mode = AppMode.order;
  ScreenType _screen = ScreenType.order;
  int _offerPrice = 120;
  ParcelType _parcelType = ParcelType.small;
  String _pickup = '742 Evergreen Terrace, Sector 4';
  String _dropoff = 'Cyber Gateway Tower B, Hub 9';
  int _walletBalance = 850;
  String? _toastMessage;
  Timer? _toastTimer;
  Timer? _courierMoveTimer;

  bool _isOnline = true;
  int _stage = 4;
  int _etaMinutes = 14;
  Offset _courierPos = const Offset(127, 155);
  bool _callingState = false;
  bool _showSosModal = false;

  final List<PendingOrder> _pendingOrders = [
    PendingOrder(
      id: 'OMW-88241',
      pickup: 'Bluestone Cafe & Roasters, Koramangala',
      dropoff: 'Green Glen Heights, Apt 402, Bellandur',
      parcelType: ParcelType.small,
      offerPrice: 120,
      broadcastTime: DateTime.now().subtract(const Duration(minutes: 4)),
      windowLabel: '14:15 – 16:15',
      accepted: true,
      acceptedPrice: 120,
      courierName: 'Aarav Sharma',
      vehicleNo: 'KA 01 EQ 4920',
      stage: 4,
    ),
  ];

  final List<PendingOrder> _sampleFeedOrders = [
    PendingOrder(
      id: 'OMW-92144',
      pickup: 'Prestige Tech Park IV, Marathahalli',
      dropoff: 'Church Street Social, MG Road',
      parcelType: ParcelType.small,
      offerPrice: 175,
      broadcastTime: DateTime.now().subtract(const Duration(minutes: 2)),
      windowLabel: '14:30 – 16:30',
      accepted: false,
    ),
    PendingOrder(
      id: 'OMW-81902',
      pickup: 'Koramangala 5th Block, 1st Cross',
      dropoff: 'Indiranagar 100ft Rd, 6th Main',
      parcelType: ParcelType.documents,
      offerPrice: 130,
      broadcastTime: DateTime.now().subtract(const Duration(minutes: 6)),
      windowLabel: '14:45 – 16:45',
      accepted: false,
    ),
    PendingOrder(
      id: 'OMW-74221',
      pickup: 'Phoenix Marketcity, Whitefield',
      dropoff: 'HSR Layout Sector 4, 14th Main',
      parcelType: ParcelType.medium,
      offerPrice: 220,
      broadcastTime: DateTime.now().subtract(const Duration(minutes: 8)),
      windowLabel: '15:00 – 17:00',
      accepted: false,
    ),
  ];

  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: '1',
      sender: 'courier',
      text: 'Namaste! I have safely collected your package and am heading towards Bellandur.',
      time: '2:16 PM',
    ),
    ChatMessage(
      id: '2',
      sender: 'courier',
      text: 'Heavy traffic near Sony World signal, taking 80ft bypass road. ETA ~14 mins.',
      time: '2:20 PM',
    ),
  ];

  AppState() {
    _startCourierSimulation();
  }

  void _startCourierSimulation() {
    _courierMoveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final random = Random();
      final dx = (random.nextDouble() * 2.0 - 0.5);
      final dy = -(random.nextDouble() * 2.0 - 0.5);
      final newX = (_courierPos.dx + dx).clamp(80.0, 260.0);
      final newY = (_courierPos.dy + dy).clamp(80.0, 240.0);
      _courierPos = Offset(newX, newY);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _courierMoveTimer?.cancel();
    super.dispose();
  }

  // Getters
  AppMode get mode => _mode;
  ScreenType get screen => _screen;
  int get offerPrice => _offerPrice;
  ParcelType get parcelType => _parcelType;
  String get pickup => _pickup;
  String get dropoff => _dropoff;
  int get walletBalance => _walletBalance;
  String? get toastMessage => _toastMessage;
  bool get isOnline => _isOnline;
  int get stage => _stage;
  int get etaMinutes => _etaMinutes;
  Offset get courierPos => _courierPos;
  bool get callingState => _callingState;
  bool get showSosModal => _showSosModal;
  List<PendingOrder> get pendingOrders => _pendingOrders;
  List<ChatMessage> get chatMessages => _chatMessages;

  List<PendingOrder> get activePendingOrders =>
      _pendingOrders.where((o) => !o.accepted).toList();

  List<PendingOrder> get acceptedOrders =>
      _pendingOrders.where((o) => o.accepted).toList();

  List<PendingOrder> get allAvailableFeedOrders {
    final list = <PendingOrder>[];
    list.addAll(_pendingOrders.where((o) => !o.accepted));
    for (final s in _sampleFeedOrders) {
      if (!_pendingOrders.any((p) => p.id == s.id) && !s.accepted) {
        list.add(s);
      }
    }
    return list;
  }

  // Mutations
  void setMode(AppMode m) {
    _mode = m;
    _screen = m == AppMode.order ? ScreenType.order : ScreenType.feed;
    showToast(m == AppMode.order
        ? 'Switched to Customer Order mode'
        : 'Switched to Courier Partner mode');
    notifyListeners();
  }

  void setScreen(ScreenType s) {
    _screen = s;
    notifyListeners();
  }

  void setOfferPrice(int price) {
    _offerPrice = max(30, price);
    notifyListeners();
  }

  void adjustOfferPrice(int delta) {
    _offerPrice = max(30, _offerPrice + delta);
    notifyListeners();
  }

  void setParcelType(ParcelType p) {
    _parcelType = p;
    notifyListeners();
  }

  void setPickup(String address) {
    _pickup = address;
    showToast('Updated pickup spot');
    notifyListeners();
  }

  void setDropoff(String address, [double? distKm]) {
    _dropoff = address;
    if (distKm != null) {
      _offerPrice = (50 + distKm * 15).round();
    }
    showToast('Updated delivery destination');
    notifyListeners();
  }

  void broadcastOrder() {
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute;
    final endH = (h + 2) % 24;
    final windowStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} – ${endH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    final id = 'OMW-${10000 + Random().nextInt(90000)}';
    final newOrder = PendingOrder(
      id: id,
      pickup: _pickup,
      dropoff: _dropoff,
      parcelType: _parcelType,
      offerPrice: _offerPrice,
      broadcastTime: now,
      windowLabel: windowStr,
      accepted: false,
    );

    _pendingOrders.insert(0, newOrder);
    _screen = ScreenType.pending;
    showToast('Broadcasted $id for ₹$_offerPrice to 12 nearby couriers!');
    notifyListeners();
  }

  void increasePendingPrice(String orderId) {
    final index = _pendingOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _pendingOrders[index].offerPrice += 5;
      _offerPrice = _pendingOrders[index].offerPrice;
      showToast('Boosted offer by +₹5 to speed up courier matching');
      notifyListeners();
    }
  }

  void setStage(int s) {
    _stage = s;
    notifyListeners();
  }

  void setEtaMinutes(int m) {
    _etaMinutes = m;
    notifyListeners();
  }

  void cancelOrder(String orderId) {
    _pendingOrders.removeWhere((o) => o.id == orderId);
    showToast('Cancelled order #$orderId');
    notifyListeners();
  }

  void courierCounter(String orderId) {
    final index = _pendingOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _pendingOrders[index].offerPrice += 5;
      _pendingOrders[index].countered = true;
      _offerPrice = _pendingOrders[index].offerPrice;
      showToast('Counter offer of +₹5 applied!');
      notifyListeners();
      return;
    }
    // Check feed orders
    final feedIndex = _sampleFeedOrders.indexWhere((o) => o.id == orderId);
    if (feedIndex != -1) {
      _sampleFeedOrders[feedIndex].offerPrice += 5;
      _sampleFeedOrders[feedIndex].countered = true;
      showToast('Counter offer of +₹5 applied!');
      notifyListeners();
    }
  }

  void courierAccept(String orderId, int price) {
    final index = _pendingOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _pendingOrders[index].accepted = true;
      _pendingOrders[index].acceptedPrice = price;
      _pendingOrders[index].stage = 3;
    } else {
      final feedIndex = _sampleFeedOrders.indexWhere((o) => o.id == orderId);
      if (feedIndex != -1) {
        final feedOrder = _sampleFeedOrders[feedIndex];
        feedOrder.accepted = true;
        feedOrder.acceptedPrice = price;
        feedOrder.stage = 3;
        _pendingOrders.insert(0, feedOrder);
      }
    }
    _offerPrice = price;
    _screen = ScreenType.tracking;
    showToast('Accepted delivery #$orderId for ₹$price! Navigation started.');
    notifyListeners();
  }

  void topUpWallet(int amount) {
    _walletBalance += amount;
    showToast('Added ₹$amount to your OMW Wallet!');
    notifyListeners();
  }

  void toggleOnlineDuty() {
    _isOnline = !_isOnline;
    showToast(_isOnline
        ? 'Courier duty online: Scanning for bids'
        : 'Courier duty paused');
    notifyListeners();
  }

  void startDirectCall() {
    _callingState = true;
    notifyListeners();
    Timer(const Duration(seconds: 4), () {
      _callingState = false;
      showToast('Call ended with Aarav Sharma');
      notifyListeners();
    });
  }

  void endDirectCall() {
    _callingState = false;
    notifyListeners();
  }

  void setSosModal(bool val) {
    _showSosModal = val;
    notifyListeners();
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      text: text.trim(),
      time: timeStr,
    );
    _chatMessages.add(userMsg);
    notifyListeners();

    // Simulated Courier reply
    Timer(const Duration(milliseconds: 1200), () {
      final lower = text.toLowerCase();
      String replyText = 'Understood! I will call you as soon as I arrive at the location.';
      if (lower.contains('otp')) {
        replyText = 'Noted! Please share the 4-digit code once I arrive at your door.';
      } else if (lower.contains('gate') || lower.contains('reception')) {
        replyText = 'Understood, I will hand it over to the lobby desk as instructed.';
      } else if (lower.contains('eta') || lower.contains('time')) {
        replyText = 'Current ETA is about 12-14 mins. Traffic on 80ft road is easing.';
      }

      final replyMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        sender: 'courier',
        text: replyText,
        time: timeStr,
      );
      _chatMessages.add(replyMsg);
      notifyListeners();
    });
  }

  void showToast(String message) {
    _toastMessage = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toastMessage = null;
      notifyListeners();
    });
    notifyListeners();
  }
}
