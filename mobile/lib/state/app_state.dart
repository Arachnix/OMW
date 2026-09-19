import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/omw_api.dart';
import '../models/omw_models.dart';
import '../models/order_model.dart';
import '../utils/geo.dart';
import 'location_service.dart';
import 'session_store.dart';

enum AppStage { splash, signIn, landing, app }

/// A feed entry: an open task plus how it fits the runner's route.
class FeedItem {
  const FeedItem({
    required this.task,
    required this.fit,
    required this.distanceKm,
    required this.detourMinutes,
    required this.detourKm,
    required this.onRoute,
  });

  final OmwTask task;
  final RouteFit fit;

  /// Runner → pickup distance.
  final double distanceKm;

  /// Extra walking the task adds to the active route.
  final int detourMinutes;
  final double detourKm;

  /// Pickup lies within the "along my route" corridor.
  final bool onRoute;
}

/// Single source of app state, backed by the OMW REST + WebSocket API.
class AppState extends ChangeNotifier {
  AppState({
    required this._api,
    this._session = const SessionStore(),
    this._location = const DeviceLocationService(),
    AppStage initialStage = AppStage.splash,
  }) : _stage = initialStage;

  final OmwApi _api;
  final SessionStore _session;
  final LocationService _location;
  StreamSubscription<LiveEvent>? _events;
  Timer? _locationPing;
  bool _disposed = false;

  static const int minOffer = 10;
  static const int maxOffer = 10000;
  static const int minWithdrawal = 50;
  static const int surgeStep = 5;
  static const int lateCancelFee = 5;

  // Flow ---------------------------------------------------------------------

  AppStage _stage;
  AppStage get stage => _stage;

  AppRole _role = AppRole.sender;
  AppRole get role => _role;

  SenderTab _senderTab = SenderTab.home;
  SenderTab get senderTab => _senderTab;

  CourierTab _courierTab = CourierTab.feed;
  CourierTab get courierTab => _courierTab;

  bool _restoring = false;
  bool _pendingSplashFinish = false;

  /// Called at launch: restores a saved session in the background.
  Future<void> restoreSession() async {
    _restoring = true;
    final saved = await _session.load();
    if (saved != null && saved.regNumber.isNotEmpty) {
      _upi = saved.upi;
      try {
        await _login(saved.regNumber, saved.name);
      } catch (_) {
        // Server unreachable or session invalid: fall back to sign-in.
      }
    }
    _restoring = false;
    if (_pendingSplashFinish) finishSplash();
  }

  void finishSplash() {
    if (_stage != AppStage.splash) return;
    if (_restoring) {
      _pendingSplashFinish = true;
      return;
    }
    _stage = _user == null ? AppStage.signIn : AppStage.landing;
    notifyListeners();
  }

  void enterAs(AppRole role, {SenderTab senderTab = SenderTab.home}) {
    _role = role;
    _senderTab = senderTab;
    _courierTab = CourierTab.feed;
    _stage = AppStage.app;
    notifyListeners();
    unawaited(refresh());
    if (role == AppRole.courier) unawaited(refreshFeed());
  }

  void enterAccount() {
    _stage = AppStage.app;
    openAccount();
  }

  void goToLanding() {
    if (_stage == AppStage.landing) return;
    _stage = AppStage.landing;
    notifyListeners();
  }

  void setRole(AppRole role) {
    if (_role == role) return;
    _role = role;
    _senderTab = SenderTab.home;
    _courierTab = CourierTab.feed;
    notifyListeners();
    if (role == AppRole.courier) unawaited(refreshFeed());
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

  void openAccount() {
    _senderTab = SenderTab.account;
    _courierTab = CourierTab.account;
    notifyListeners();
  }

  void openWallet() {
    _senderTab = SenderTab.wallet;
    _courierTab = CourierTab.earnings;
    notifyListeners();
  }

  // Session ------------------------------------------------------------------

  OmwUser? _user;
  OmwUser? get user => _user;
  String get userId => _user?.id ?? '';

  String? _upi;

  /// Payout / payment UPI handle, set by the user.
  String? get upi => _upi;

  Future<void> setUpi(String value) async {
    _upi = value.trim();
    notifyListeners();
    await _session.saveUpi(_upi!);
  }

  /// Email sign-in. The backend keys students by registration number, so the
  /// email doubles as the identifier and the name is derived from it.
  Future<void> signIn(String email) =>
      _loginAndEnter(email.trim().toLowerCase(), nameFromEmail(email));

  /// Demo accounts seeded by the backend (src/data/store.js).
  Future<void> signInDemo({required bool runner}) => runner
      ? _loginAndEnter('22BEE0819', 'Rohan Mehta')
      : _loginAndEnter('22BCE1142', 'Rohit Verma');

  Future<void> _loginAndEnter(String reg, String name) async {
    await _login(reg, name);
    await _session.save(reg, name);
    _stage = AppStage.landing;
    notifyListeners();
  }

  Future<void> _login(String reg, String name) async {
    final result = await _api.login(regNumber: reg, name: name);
    _user = result.user;
    _wallet = result.wallet;
    notifyListeners();
    _listen();
    unawaited(refresh());
    unawaited(loadLocations());
  }

  Future<void> signOut() async {
    await _session.clear();
    await _events?.cancel();
    _events = null;
    _locationPing?.cancel();
    _user = null;
    _wallet = Wallet.empty;
    _transactions = [];
    _tasks = {};
    _knownStatus.clear();
    _notices.clear();
    _log.clear();
    _feed = [];
    _online = false;
    _upi = null;
    _role = AppRole.sender;
    _senderTab = SenderTab.home;
    _courierTab = CourierTab.feed;
    _stage = AppStage.signIn;
    notifyListeners();
  }

  static String nameFromEmail(String email) {
    final local = email.split('@').first;
    final parts = local
        .split(RegExp(r'[._\-+]'))
        .map((p) => p.replaceAll(RegExp(r'\d'), ''))
        .where((p) => p.isNotEmpty);
    final name = parts
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
    return name.isEmpty ? 'OMW Student' : name;
  }

  // Data ---------------------------------------------------------------------

  Wallet _wallet = Wallet.empty;
  Wallet get wallet => _wallet;

  List<WalletTx> _transactions = [];
  List<WalletTx> get transactions => _transactions;

  List<CampusLocation> _locations = [];
  List<CampusLocation> get locations => _locations;

  CampusLocation? locationById(String? id) {
    for (final l in _locations) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// All tasks the app knows about, by id.
  Map<String, OmwTask> _tasks = {};
  OmwTask? taskById(String id) => _tasks[id];

  String? _loadError;

  /// Last error from a background refresh.
  String? get loadError => _loadError;

  Future<void> loadLocations() async {
    if (_locations.isNotEmpty) return;
    try {
      _locations = await _api.locations();
      _pickupId ??= 'loc-foody-st';
      _dropId ??= 'loc-q-block';
      _routeFromId ??= 'loc-sjt';
      _routeToId ??= 'loc-q-block';
      _rebuildFeed();
      if (!_disposed) notifyListeners();
      unawaited(updateQuote());
    } catch (e) {
      _loadError = '$e';
      if (!_disposed) notifyListeners();
    }
  }

  /// Reloads wallet, ledger, profile and tasks.
  Future<void> refresh() async {
    final id = _user?.id;
    if (id == null) return;
    try {
      final results = await Future.wait([
        _api.wallet(id),
        _api.transactions(id),
        _api.tasks(),
        _api.profile(id),
      ]);
      _wallet = results[0] as Wallet;
      _transactions = results[1] as List<WalletTx>;
      _mergeTasks(results[2] as List<OmwTask>);
      _user = results[3] as OmwUser;
      _loadError = null;
      _rebuildFeed();
    } catch (e) {
      _loadError = '$e';
    }
    if (!_disposed) notifyListeners();
  }

  void _mergeTasks(List<OmwTask> list) {
    for (final t in list) {
      _knownStatus.putIfAbsent(t.id, () => t.status);
      _tasks[t.id] = t;
    }
  }

  Future<void> _refreshWallet() async {
    final id = _user?.id;
    if (id == null) return;
    try {
      _wallet = await _api.wallet(id);
      _transactions = await _api.transactions(id);
      if (!_disposed) notifyListeners();
    } catch (_) {}
  }

  // Sender: my requests ------------------------------------------------------

  List<OmwTask> get myRequests {
    final list = _tasks.values.where((t) => t.requesterId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<OmwTask> get activeRequests =>
      myRequests.where((t) => t.status.isActive).toList();

  List<OmwTask> get pastRequests =>
      myRequests.where((t) => !t.status.isActive).toList();

  int get waitingCount =>
      myRequests.where((t) => t.status == TaskStatus.open).length;

  // Sender: new request form -------------------------------------------------

  String? _pickupId;
  String? _dropId;
  CampusLocation? get pickup => locationById(_pickupId);
  CampusLocation? get drop => locationById(_dropId);

  ParcelType? _parcel = ParcelType.small;
  ParcelType? get parcel => _parcel;

  int _offer = 20;
  int get offer => _offer;
  bool _offerEdited = false;

  RouteEstimate? _quote;

  /// Walking + queue estimate for the selected pickup → drop.
  RouteEstimate? get quote => _quote;

  final Set<DeliverySource> _sources = {};
  Set<DeliverySource> get sources => Set.unmodifiable(_sources);

  bool _broadcasting = false;
  bool get broadcasting => _broadcasting;

  bool get canBroadcast =>
      !_broadcasting &&
      _parcel != null &&
      _pickupId != null &&
      _dropId != null &&
      _pickupId != _dropId;

  void setPickup(String id) {
    _pickupId = id;
    notifyListeners();
    unawaited(updateQuote());
  }

  void setDrop(String id) {
    _dropId = id;
    notifyListeners();
    unawaited(updateQuote());
  }

  void selectParcel(ParcelType type) {
    _parcel = type;
    notifyListeners();
  }

  void clearParcel() {
    _parcel = null;
    notifyListeners();
  }

  void toggleSource(DeliverySource source) {
    if (!_sources.remove(source)) _sources.add(source);
    notifyListeners();
  }

  /// Fetches the backend's suggested bounty and route estimate.
  Future<void> updateQuote() async {
    final p = _pickupId, d = _dropId;
    if (p == null || d == null || p == d) return;
    try {
      final results = await Future.wait([
        _api.route(p, d),
        _api.suggestWager(p, d),
      ]);
      _quote = results[0] as RouteEstimate;
      if (!_offerEdited) _offer = results[1] as int;
      if (!_disposed) notifyListeners();
    } catch (_) {}
  }

  /// Returns an error message, or null when [raw] was accepted as the offer.
  String? setOffer(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) return 'Enter a whole rupee amount';
    if (value < minOffer) return 'Minimum offer is ₹$minOffer';
    if (value > maxOffer) return 'Maximum offer is ₹$maxOffer';
    _offer = value;
    _offerEdited = true;
    notifyListeners();
    return null;
  }

  /// Publishes the request; tokens are locked in escrow by the backend.
  Future<OmwTask> broadcast() async {
    final parcel = _parcel;
    if (!canBroadcast || parcel == null) {
      throw const ApiException('Choose a pickup, destination and parcel.');
    }
    _broadcasting = true;
    notifyListeners();
    try {
      final notes = _sources.isEmpty
          ? ''
          : 'Source: ${_sources.map((s) => s.label).join(', ')}';
      final task = await _api.createTask(
        requesterId: userId,
        title: '${parcel.label} delivery',
        category: parcel.category,
        pickupId: _pickupId!,
        dropId: _dropId!,
        wager: _offer,
        notes: notes,
      );
      _tasks[task.id] = task;
      _knownStatus[task.id] = task.status;
      unawaited(_refreshWallet());
      return task;
    } finally {
      _broadcasting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<CancelResult> cancelRequest(OmwTask task, {String? reason}) async {
    final result = await _api.cancel(task.id, reason: reason);
    _put(result.task);
    unawaited(_refreshWallet());
    return result;
  }

  Future<OmwTask> surge(OmwTask task) async {
    final updated = await _api.surge(task.id, surgeStep);
    _put(updated);
    unawaited(_refreshWallet());
    return updated;
  }

  Future<OmwTask> reloadTask(String id) async {
    final t = await _api.task(id);
    _put(t);
    return t;
  }

  void _put(OmwTask task) {
    _tasks[task.id] = task;
    _knownStatus[task.id] = task.status;
    if (!_disposed) notifyListeners();
  }

  // Courier: route & feed ----------------------------------------------------

  String? _routeFromId;
  String? _routeToId;
  CampusLocation? get routeFrom => locationById(_routeFromId);
  CampusLocation? get routeTo => locationById(_routeToId);

  /// Device position when the runner shared GPS; otherwise the route start.
  ({double lat, double lng})? _gps;

  ({double lat, double lng})? get runnerPosition {
    if (_gps != null) return _gps;
    final from = routeFrom;
    return from == null ? null : (lat: from.lat, lng: from.lng);
  }

  bool _online = false;

  /// Runner is available for "along your route" alerts.
  bool get online => _online;

  RunnerFilter _filter = RunnerFilter.alongRoute;
  RunnerFilter get filter => _filter;

  List<FeedItem> _feed = [];
  bool _feedLoading = false;
  bool get feedLoading => _feedLoading;
  String? _feedError;
  String? get feedError => _feedError;

  double get routeKm {
    final a = routeFrom, b = routeTo;
    if (a == null || b == null) return 0;
    return Geo.walkMeters(a.lat, a.lng, b.lat, b.lng) / 1000;
  }

  int get routeMinutes => Geo.walkMinutes(routeKm * 1000);

  void setRoute(String fromId, String toId) {
    _routeFromId = fromId;
    _routeToId = toId;
    _gps = null;
    notifyListeners();
    _pingLocation();
    unawaited(refreshFeed());
  }

  /// Uses the device location as the runner position. Throws
  /// [LocationFailure] when GPS is unavailable or off campus.
  Future<void> useDeviceLocation() async {
    final pos = await _location.current();
    final nearest = _nearestLocation(pos.lat, pos.lng);
    if (nearest == null ||
        Geo.meters(pos.lat, pos.lng, nearest.lat, nearest.lng) > 3000) {
      throw const LocationFailure(
        'Your location is outside VIT Vellore campus.',
      );
    }
    _routeFromId = nearest.id;
    _gps = pos;
    notifyListeners();
    _pingLocation();
    await refreshFeed();
  }

  CampusLocation? _nearestLocation(double lat, double lng) {
    CampusLocation? best;
    var bestD = double.infinity;
    for (final l in _locations) {
      final d = Geo.meters(lat, lng, l.lat, l.lng);
      if (d < bestD) {
        bestD = d;
        best = l;
      }
    }
    return best;
  }

  void setOnline(bool value) {
    _online = value;
    _locationPing?.cancel();
    if (value) {
      _pingLocation();
      _locationPing = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _pingLocation(),
      );
    }
    notifyListeners();
  }

  void _pingLocation() {
    final pos = runnerPosition;
    if (!_online || pos == null || _user == null) return;
    _api.sendRunnerLocation(userId, pos.lat, pos.lng);
  }

  void setFilter(RunnerFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    final pos = runnerPosition;
    _feedLoading = true;
    notifyListeners();
    try {
      final from = routeFrom, to = routeTo;
      final heading = from != null && to != null
          ? Geo.bearing(from.lat, from.lng, to.lat, to.lng)
          : 0.0;
      final list = await _api.tasks(
        lat: pos?.lat,
        lng: pos?.lng,
        heading: heading,
      );
      _mergeTasks(list);
      _feedError = null;
    } catch (e) {
      _feedError = '$e';
    }
    _feedLoading = false;
    _rebuildFeed();
    if (!_disposed) notifyListeners();
  }

  void _rebuildFeed() {
    final from = routeFrom, to = routeTo, pos = runnerPosition;
    final items = <FeedItem>[];
    for (final t in _tasks.values) {
      if (t.status != TaskStatus.open || t.requesterId == userId) continue;
      items.add(_fit(t, from, to, pos));
    }
    items.sort((a, b) {
      final byFit = a.fit.index.compareTo(b.fit.index);
      return byFit != 0 ? byFit : a.distanceKm.compareTo(b.distanceKm);
    });
    _feed = items;
  }

  FeedItem _fit(
    OmwTask t,
    CampusLocation? from,
    CampusLocation? to,
    ({double lat, double lng})? pos,
  ) {
    final toPickup = pos == null
        ? 0.0
        : Geo.walkMeters(pos.lat, pos.lng, t.pickupLat, t.pickupLng);
    var offRoute = double.infinity;
    var detour = 0.0;
    if (from != null && to != null) {
      offRoute = Geo.toSegment(
        t.pickupLat,
        t.pickupLng,
        from.lat,
        from.lng,
        to.lat,
        to.lng,
      );
      final direct = Geo.walkMeters(from.lat, from.lng, to.lat, to.lng);
      final via =
          Geo.walkMeters(from.lat, from.lng, t.pickupLat, t.pickupLng) +
          Geo.walkMeters(t.pickupLat, t.pickupLng, t.dropLat, t.dropLng) +
          Geo.walkMeters(t.dropLat, t.dropLng, to.lat, to.lng);
      detour = (via - direct).clamp(0, double.infinity).toDouble();
    }
    final fit = offRoute <= 80
        ? RouteFit.perfect
        : offRoute <= 200
        ? RouteFit.near
        : RouteFit.detour;
    return FeedItem(
      task: t,
      fit: fit,
      distanceKm: toPickup / 1000,
      detourMinutes: Geo.walkMinutes(detour),
      detourKm: detour / 1000,
      onRoute: offRoute <= 200,
    );
  }

  List<FeedItem> get allFeed => _feed;

  List<FeedItem> feedFor(RunnerFilter f) => switch (f) {
    RunnerFilter.alongRoute => _feed.where((i) => i.onRoute).toList(),
    RunnerFilter.nearby => _feed.where((i) => i.distanceKm <= 0.8).toList(),
    RunnerFilter.all => _feed,
  };

  List<FeedItem> get visibleFeed => feedFor(_filter);

  FeedItem fitFor(OmwTask t) => _fit(t, routeFrom, routeTo, runnerPosition);

  // Courier: jobs ------------------------------------------------------------

  List<OmwTask> get myJobs {
    final list = _tasks.values.where((t) => t.runnerId == userId).toList()
      ..sort(
        (a, b) =>
            (b.claimedAt ?? b.createdAt).compareTo(a.claimedAt ?? a.createdAt),
      );
    return list;
  }

  List<OmwTask> get activeJobs =>
      myJobs.where((t) => t.status.isActive).toList();

  Future<OmwTask> claim(OmwTask task) async {
    final claimed = await _api.claim(task.id, userId);
    _put(claimed);
    _rebuildFeed();
    unawaited(_refreshWallet());
    return claimed;
  }

  Future<OmwTask> confirmPickup(OmwTask task, String otp) async {
    final t = await _api.verifyPickup(task.id, otp);
    _put(t);
    return t;
  }

  Future<OmwTask> verifyDelivery(OmwTask task, String otp) async {
    final t = await _api.verifyDelivery(task.id, otp);
    _put(t);
    unawaited(refresh());
    return t;
  }

  /// Tells the requester the runner is at the drop-off.
  void announceArrival(OmwTask task) => _api.sendRunnerArrived(task.id, userId);

  Future<OmwTask> dropJob(OmwTask task, String reason) async {
    final t = await _api.drop(task.id, userId, reason);
    _put(t);
    _rebuildFeed();
    unawaited(refresh());
    return t;
  }

  // Wallet -------------------------------------------------------------------

  Future<PurchaseResult> buyTokens(TokenPack pack) async {
    final r = await _api.buyTokens(userId, pack.tokens);
    await _refreshWallet();
    return r;
  }

  Future<void> withdraw(int tokens) async {
    final upi = _upi;
    if (upi == null || upi.isEmpty) {
      throw const ApiException('Add a UPI ID to withdraw.');
    }
    await _api.withdraw(userId, tokens, upi);
    await _refreshWallet();
  }

  int get earningsThisMonth {
    final now = DateTime.now();
    return _transactions
        .where(
          (t) =>
              t.isEarning &&
              t.timestamp.year == now.year &&
              t.timestamp.month == now.month,
        )
        .fold(0, (sum, t) => sum + t.tokens);
  }

  ({int amount, int count}) get earningsToday {
    final now = DateTime.now();
    final today = _transactions.where(
      (t) =>
          t.type == TxType.bountyPayout &&
          t.timestamp.year == now.year &&
          t.timestamp.month == now.month &&
          t.timestamp.day == now.day,
    );
    return (amount: today.fold(0, (s, t) => s + t.tokens), count: today.length);
  }

  int get deliveriesCompleted => _user?.completedTasks ?? 0;

  // Live events & notices ----------------------------------------------------

  final Map<String, TaskStatus> _knownStatus = {};
  final List<AppNotice> _notices = [];
  final List<AppNotice> _log = [];

  /// Oldest undismissed notice for the current role (shown as a sheet).
  AppNotice? get pendingNotice {
    for (final n in _notices) {
      final forCourier = n.kind == NoticeKind.alongRoute;
      if (forCourier == (_role == AppRole.courier)) return n;
    }
    return null;
  }

  void dismissNotice(AppNotice notice) {
    if (_notices.remove(notice)) notifyListeners();
  }

  /// Notification history for the Notifications screen (newest first).
  List<AppNotice> get notificationLog => List.unmodifiable(_log);

  void removeFromLog(AppNotice notice) {
    if (_log.remove(notice)) notifyListeners();
  }

  void _notify(AppNotice n, {bool sheet = true}) {
    if (sheet) _notices.add(n);
    _log.insert(0, n);
    notifyListeners();
  }

  void _listen() {
    _events?.cancel();
    _events = _api.events().listen(_onEvent);
  }

  Future<void> _onEvent(LiveEvent e) async {
    if (_user == null) return;
    switch (e.type) {
      case 'TASK_STATE_CHANGED':
        final t = e.task;
        if (t == null) return;
        final before = _knownStatus[t.id];
        _tasks[t.id] = t;
        _knownStatus[t.id] = t.status;
        final mine = t.requesterId == userId;
        final byOther = e.actorId != userId;
        if (mine && byOther && before != t.status) {
          switch (t.status) {
            case TaskStatus.claimed:
              _notify(AppNotice(kind: NoticeKind.accepted, task: t));
            case TaskStatus.inTransit:
              _notify(AppNotice(kind: NoticeKind.pickedUp, task: t));
            case TaskStatus.delivered:
              _notify(
                AppNotice(kind: NoticeKind.delivered, task: t),
                sheet: false,
              );
            case TaskStatus.open when before == TaskStatus.claimed:
              _notices.removeWhere(
                (n) => n.task.id == t.id && n.kind == NoticeKind.accepted,
              );
              _notify(AppNotice(kind: NoticeKind.cancelledByCourier, task: t));
            default:
              break;
          }
        }
        if (mine || t.runnerId == userId || e.actorId == userId) {
          unawaited(_refreshWallet());
        }
        _rebuildFeed();
        notifyListeners();
      case 'RUNNER_ARRIVED':
        final t = e.taskId == null ? null : _tasks[e.taskId];
        if (t != null && t.requesterId == userId && e.runnerId != userId) {
          _notify(AppNotice(kind: NoticeKind.arrived, task: t));
        }
      case 'EN_ROUTE_TASK_ALERT':
        if (e.runnerId != userId || !_online || e.taskId == null) return;
        try {
          final t = await _api.task(e.taskId!);
          if (t.requesterId == userId || t.status != TaskStatus.open) return;
          _tasks[t.id] = t;
          final item = fitFor(t);
          _rebuildFeed();
          _notify(
            AppNotice(
              kind: NoticeKind.alongRoute,
              task: t,
              detourKm: item.detourKm,
              detourMinutes: item.detourMinutes,
            ),
          );
        } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _events?.cancel();
    _locationPing?.cancel();
    super.dispose();
  }
}
