import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/order_model.dart';

enum AppStage { splash, signIn, landing, app }

/// Single source of UI state. Everything is local and in-memory: there is no
/// real authentication, payment or network layer.
class AppState extends ChangeNotifier {
  AppState({AppStage initialStage = AppStage.splash}) : _stage = initialStage;

  static const int minFare = 30;
  static const int maxFare = 10000;

  // Flow ---------------------------------------------------------------------

  AppStage _stage;
  AppStage get stage => _stage;

  String? _email;
  String? get email => _email;

  AppRole _role = AppRole.sender;
  AppRole get role => _role;

  SenderTab _senderTab = SenderTab.home;
  SenderTab get senderTab => _senderTab;

  CourierTab _courierTab = CourierTab.feed;
  CourierTab get courierTab => _courierTab;

  void finishSplash() {
    if (_stage != AppStage.splash) return;
    _stage = AppStage.signIn;
    notifyListeners();
  }

  /// Mock sign-in: records the identity locally and opens the landing.
  void signIn(String identity) {
    _email = identity;
    _stage = AppStage.landing;
    notifyListeners();
  }

  /// Landing ORDER / DELIVER cards: open the role's shell on [senderTab]
  /// (sender) or the feed (courier).
  void enterAs(AppRole role, {SenderTab senderTab = SenderTab.home}) {
    _role = role;
    _senderTab = senderTab;
    _courierTab = CourierTab.feed;
    _stage = AppStage.app;
    notifyListeners();
  }

  /// Opens the Account tab for the current role.
  void enterAccount() {
    _stage = AppStage.app;
    openAccount();
  }

  /// Header mascot: back to the landing.
  void goToLanding() {
    if (_stage == AppStage.landing) return;
    _stage = AppStage.landing;
    notifyListeners();
  }

  void signOut() {
    _email = null;
    _role = AppRole.sender;
    _senderTab = SenderTab.home;
    _courierTab = CourierTab.feed;
    _stage = AppStage.signIn;
    notifyListeners();
  }

  void setRole(AppRole role) {
    if (_role == role) return;
    _role = role;
    _senderTab = SenderTab.home;
    _courierTab = CourierTab.feed;
    notifyListeners();
  }

  void setSenderTab(SenderTab tab) {
    if (_senderTab == tab) return;
    _senderTab = tab;
    notifyListeners();
  }

  void setCourierTab(CourierTab tab) {
    if (_courierTab == tab) return;
    _courierTab = tab;
    notifyListeners();
  }

  /// Header avatar: the role's account tab.
  void openAccount() {
    _senderTab = SenderTab.account;
    _courierTab = CourierTab.account;
    notifyListeners();
  }

  // Sender: new request ------------------------------------------------------

  String _pickup = MockData.defaultPickup;
  String get pickup => _pickup;

  String _destination = MockData.defaultDestination;
  String get destination => _destination;

  ParcelType? _parcel = ParcelType.small;
  ParcelType? get parcel => _parcel;

  int _offer = ParcelType.small.suggestedFare;
  int get offer => _offer;

  final Set<DeliverySource> _sources = {};
  Set<DeliverySource> get sources => Set.unmodifiable(_sources);

  void toggleSource(DeliverySource source) {
    if (!_sources.remove(source)) _sources.add(source);
    notifyListeners();
  }

  bool _broadcasting = false;
  bool get broadcasting => _broadcasting;

  bool get canBroadcast =>
      !_broadcasting &&
      _parcel != null &&
      _pickup.isNotEmpty &&
      _destination.isNotEmpty;

  void setPickup(String address) {
    _pickup = address.trim();
    notifyListeners();
  }

  void setDestination(String address) {
    _destination = address.trim();
    notifyListeners();
  }

  void swapRoute() {
    final p = _pickup;
    _pickup = _destination;
    _destination = p;
    notifyListeners();
  }

  void selectParcel(ParcelType type) {
    _parcel = type;
    _offer = type.suggestedFare;
    notifyListeners();
  }

  void clearParcel() {
    _parcel = null;
    notifyListeners();
  }

  /// Returns an error message, or null when [raw] was accepted as the offer.
  String? setOffer(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) return 'Enter a whole rupee amount';
    if (value < minFare) return 'Minimum offer is ₹$minFare';
    if (value > maxFare) return 'Maximum offer is ₹$maxFare';
    _offer = value;
    notifyListeners();
    return null;
  }

  Future<DeliveryRequest?> broadcast() async {
    final parcel = _parcel;
    if (!canBroadcast || parcel == null) return null;
    _broadcasting = true;
    notifyListeners();

    // Simulated round-trip so the button can show its busy state.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final request = DeliveryRequest(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch % 10000}',
      pickup: _pickup,
      destination: _destination,
      parcel: parcel,
      fare: _offer,
      distanceKm: 4.8,
      etaMinutes: 18,
      createdAt: DateTime.now(),
      sources: Set.of(_sources),
    );
    _history.insert(0, request);
    _feed.insert(0, request);
    _broadcasting = false;
    notifyListeners();
    return request;
  }

  // Sender: activity ---------------------------------------------------------

  final List<DeliveryRequest> _history = MockData.senderHistory();
  List<DeliveryRequest> get history => List.unmodifiable(_history);

  int get openRequestCount =>
      _history.where((r) => r.status != DeliveryStatus.delivered).length;

  // Courier: feed ------------------------------------------------------------

  final List<DeliveryRequest> _feed = MockData.feed();
  final List<DeliveryRequest> _accepted = [];

  FeedFilter _filter = FeedFilter.all;
  FeedFilter get filter => _filter;

  List<DeliveryRequest> get visibleFeed =>
      _feed.where(_filter.matches).toList(growable: false);

  List<DeliveryRequest> get accepted => List.unmodifiable(_accepted);

  void setFilter(FeedFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// Courier accepts [request]. If it is one of the sender's own requests,
  /// the sender gets an "Order Accepted" notice. Returns the updated request.
  DeliveryRequest accept(DeliveryRequest request) {
    _feed.removeWhere((r) => r.id == request.id);
    final updated = request.copyWith(status: DeliveryStatus.accepted);
    _accepted.insert(0, updated);
    final i = _history.indexWhere((r) => r.id == request.id);
    if (i != -1) {
      _history[i] = updated;
      _notices.add(SenderNotice(kind: NoticeKind.accepted, request: updated));
    }
    notifyListeners();
    return updated;
  }

  /// Courier drops an accepted job (mock: vehicle issue). The sender gets an
  /// "Order Cancelled" notice for their own requests.
  void cancelAccepted(DeliveryRequest request) {
    _accepted.removeWhere((r) => r.id == request.id);
    final reopened = request.copyWith(status: DeliveryStatus.broadcasted);
    final i = _history.indexWhere((r) => r.id == request.id);
    if (i != -1) {
      _history[i] = reopened;
      // A pending "accepted" notice is now stale.
      _notices.removeWhere((n) => n.request.id == request.id);
      _notices.add(
        SenderNotice(
          kind: NoticeKind.cancelled,
          request: reopened,
          reason: MockData.cancelReason,
        ),
      );
    }
    // Back on the feed right away ("automatically looking for a replacement").
    _feed.removeWhere((r) => r.id == request.id);
    _feed.insert(0, reopened);
    notifyListeners();
  }

  // Sender: notices ----------------------------------------------------------

  final List<SenderNotice> _notices = [];

  /// Oldest undismissed notice, shown over the sender shell.
  SenderNotice? get pendingNotice => _notices.isEmpty ? null : _notices.first;

  void dismissNotice(SenderNotice notice) {
    if (_notices.remove(notice)) notifyListeners();
  }

  /// "Search New Partner": put the request back on the courier feed.
  void searchNewPartner(DeliveryRequest request) {
    _feed.removeWhere((r) => r.id == request.id);
    _feed.insert(0, request.copyWith(status: DeliveryStatus.broadcasted));
    notifyListeners();
  }
}
