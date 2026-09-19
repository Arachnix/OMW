/// Data models mirroring the OMW backend JSON (src/data/store.js and routes).
library;

import 'order_model.dart';

double _num(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;

int _int(Object? v, [int fallback = 0]) =>
    v is num ? v.round() : int.tryParse('$v') ?? fallback;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

class OmwUser {
  const OmwUser({
    required this.id,
    required this.name,
    required this.regNumber,
    required this.hostelBlock,
    required this.trustScore,
    required this.completedTasks,
    required this.isRestricted,
    this.restrictionNotice,
    this.role = 'student',
  });

  factory OmwUser.fromJson(Map<String, dynamic> j) => OmwUser(
    id: j['id'] as String,
    name: (j['name'] as String?) ?? 'Student',
    regNumber: (j['regNumber'] as String?) ?? (j['regHash'] as String?) ?? '',
    hostelBlock: (j['hostelBlock'] as String?) ?? '',
    trustScore: _num(j['trustScore'], 5),
    completedTasks: _int(j['completedTasks']),
    isRestricted: j['isRestricted'] == true,
    restrictionNotice: j['restrictionNotice'] as String?,
    role: (j['role'] as String?) ?? 'student',
  );

  final String id;
  final String name;
  final String regNumber;
  final String hostelBlock;
  final double trustScore;
  final int completedTasks;
  final bool isRestricted;
  final String? restrictionNotice;
  final String role;

  String get firstName => name.split(' ').first;
}

class Wallet {
  const Wallet({
    required this.available,
    required this.escrow,
    required this.staked,
  });

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
    available: _int(j['availableTokens']),
    escrow: _int(j['escrowLocked']),
    staked: _int(j['runnerStaked']),
  );

  static const empty = Wallet(available: 0, escrow: 0, staked: 0);

  /// Tokens the user can spend or withdraw.
  final int available;

  /// Tokens locked for the user's open requests.
  final int escrow;

  /// Runner commitment deposits currently locked.
  final int staked;

  int get total => available + escrow + staked;
}

enum TxType {
  purchase,
  withdrawal,
  voucher,
  escrowLock,
  escrowRelease,
  escrowRefund,
  bountyPayout,
  stakeLock,
  stakeReturn,
  stakeSlashed,
  cancellationFee,
  other,
}

class WalletTx {
  const WalletTx({
    required this.id,
    required this.type,
    required this.tokens,
    required this.reference,
    required this.timestamp,
    this.taskId,
  });

  factory WalletTx.fromJson(Map<String, dynamic> j) => WalletTx(
    id: j['id'] as String,
    type: switch (j['type']) {
      'TOKEN_PURCHASE' => TxType.purchase,
      'FIAT_WITHDRAWAL' => TxType.withdrawal,
      'VOUCHER_REDEMPTION' => TxType.voucher,
      'ESCROW_LOCK' => TxType.escrowLock,
      'ESCROW_RELEASE' => TxType.escrowRelease,
      'ESCROW_REFUND' => TxType.escrowRefund,
      'BOUNTY_PAYOUT' => TxType.bountyPayout,
      'RUNNER_STAKE_LOCK' => TxType.stakeLock,
      'STAKE_RETURN' => TxType.stakeReturn,
      'STAKE_SLASHED' => TxType.stakeSlashed,
      'CANCELLATION_FEE' => TxType.cancellationFee,
      _ => TxType.other,
    },
    tokens: _int(j['tokens']),
    reference: (j['reference'] as String?) ?? '',
    timestamp: _date(j['timestamp']) ?? DateTime.now(),
    taskId: j['referenceTaskId'] as String?,
  );

  final String id;
  final TxType type;

  /// Signed token change (+ credit, − debit).
  final int tokens;
  final String reference;
  final DateTime timestamp;
  final String? taskId;

  bool get isEarning =>
      type == TxType.bountyPayout || type == TxType.cancellationFee;

  String get title => switch (type) {
    TxType.purchase => 'Bought $tokens Tokens',
    TxType.withdrawal => 'Withdrawal To UPI',
    TxType.voucher => 'Campus Voucher',
    TxType.escrowLock => 'Delivery Request',
    TxType.escrowRelease => 'Delivery Completed',
    TxType.escrowRefund => 'Escrow Refund',
    TxType.bountyPayout => 'Delivery Earnings',
    TxType.stakeLock => 'Runner Stake Locked',
    TxType.stakeReturn => 'Runner Stake Returned',
    TxType.stakeSlashed => 'Runner Stake Slashed',
    TxType.cancellationFee => 'Cancellation Fee',
    TxType.other => 'Wallet Activity',
  };
}

class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
  });

  factory CampusLocation.fromJson(Map<String, dynamic> j) {
    final c = (j['coords'] as List?) ?? const [0, 0];
    return CampusLocation(
      id: j['id'] as String,
      name: j['name'] as String,
      category: (j['category'] as String?) ?? 'facility',
      lat: _num(c[0]),
      lng: _num(c[1]),
    );
  }

  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;

  /// First part of the landmark name, e.g. "Foody Street" from
  /// "Foody Street Campus Boulevard".
  String get shortName => shortLandmark(name);

  String get categoryLabel => switch (category) {
    'food' => 'Food',
    'hostel' => 'Hostel',
    'academic' => 'Academic Block',
    'gate' => 'Campus Gate',
    _ => 'Facility',
  };
}

enum TaskStatus { open, claimed, inTransit, delivered, cancelled }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
    TaskStatus.open => 'Waiting for courier',
    TaskStatus.claimed => 'Order Accepted & on Route',
    TaskStatus.inTransit => 'Package Picked Up',
    TaskStatus.delivered => 'Delivered',
    TaskStatus.cancelled => 'Cancelled',
  };

  bool get isActive =>
      this == TaskStatus.open ||
      this == TaskStatus.claimed ||
      this == TaskStatus.inTransit;
}

TaskStatus _status(Object? s) => switch ('$s'.toUpperCase()) {
  'CLAIMED' => TaskStatus.claimed,
  'IN_TRANSIT' => TaskStatus.inTransit,
  'DELIVERED' => TaskStatus.delivered,
  'CANCELLED' => TaskStatus.cancelled,
  _ => TaskStatus.open,
};

/// A delivery request ("task") as stored by the backend.
class OmwTask {
  const OmwTask({
    required this.id,
    required this.title,
    required this.category,
    required this.requesterId,
    required this.requesterName,
    required this.requesterTrust,
    required this.pickupId,
    required this.pickupName,
    required this.dropId,
    required this.dropName,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.wager,
    required this.notes,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.runnerId,
    this.runnerName,
    this.pickupOtp,
    this.deliveryOtp,
    this.runnerStake = 0,
    this.claimedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.surgeActive = false,
    this.distanceToPickupMeters,
    this.priorityScore,
    this.dropReason,
    this.cancelledBy,
    this.cancelReason,
  });

  factory OmwTask.fromJson(Map<String, dynamic> j) {
    final p = (j['pickupCoords'] as List?) ?? const [0, 0];
    final d = (j['dropCoords'] as List?) ?? const [0, 0];
    return OmwTask(
      id: j['id'] as String,
      title: (j['title'] as String?) ?? 'Delivery request',
      category: (j['category'] as String?) ?? 'general',
      requesterId: (j['requesterId'] as String?) ?? '',
      requesterName: (j['requesterName'] as String?) ?? 'Student',
      requesterTrust: _num(j['requesterTrustScore'], 5),
      pickupId: (j['pickupNodeId'] as String?) ?? '',
      pickupName: (j['pickupNodeName'] as String?) ?? '',
      dropId: (j['dropNodeId'] as String?) ?? '',
      dropName: (j['dropNodeName'] as String?) ?? '',
      pickupLat: _num(p[0]),
      pickupLng: _num(p[1]),
      dropLat: _num(d[0]),
      dropLng: _num(d[1]),
      wager: _int(j['wager']),
      notes: (j['notes'] as String?) ?? '',
      urgency: (j['urgency'] as String?) ?? 'normal',
      status: _status(j['status']),
      createdAt: _date(j['createdAt']) ?? DateTime.now(),
      runnerId: j['runnerId'] as String?,
      runnerName: j['runnerName'] as String?,
      pickupOtp: j['pickupOtp'] as String?,
      deliveryOtp: j['deliveryOtp'] as String?,
      runnerStake: _int(j['runnerStakeLocked']),
      claimedAt: _date(j['claimedAt']),
      pickedUpAt: _date(j['pickedUpAt']),
      deliveredAt: _date(j['deliveredAt']),
      surgeActive: j['surgeActive'] == true,
      distanceToPickupMeters: j['distanceToPickupMeters'] == null
          ? null
          : _num(j['distanceToPickupMeters']),
      priorityScore: j['priorityScore'] == null
          ? null
          : _num(j['priorityScore']),
      dropReason: j['dropReason'] as String?,
      cancelledBy: j['cancelledBy'] as String?,
      cancelReason: j['cancelReason'] as String?,
    );
  }

  final String id;
  final String title;
  final String category;
  final String requesterId;
  final String requesterName;
  final double requesterTrust;
  final String pickupId;
  final String pickupName;
  final String dropId;
  final String dropName;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  /// Bounty in tokens (1 token = ₹1).
  final int wager;
  final String notes;
  final String urgency;
  final TaskStatus status;
  final DateTime createdAt;
  final String? runnerId;
  final String? runnerName;
  final String? pickupOtp;
  final String? deliveryOtp;
  final int runnerStake;
  final DateTime? claimedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final bool surgeActive;
  final double? distanceToPickupMeters;
  final double? priorityScore;
  final String? dropReason;
  final String? cancelledBy;
  final String? cancelReason;

  /// Parcel size, recovered from the category the app sends.
  ParcelType get parcel => switch (category) {
    'documents' => ParcelType.documents,
    'medium' || 'electronics' => ParcelType.medium,
    _ => ParcelType.small,
  };

  String get categoryLabel => switch (category) {
    'food' => 'Food',
    'documents' => 'Documents',
    'printout' => 'Printout',
    'medium' => 'Medium Box',
    'small' => 'Small Box',
    _ =>
      category.isEmpty
          ? 'General'
          : '${category[0].toUpperCase()}${category.substring(1)}',
  };

  String get shortPickup => shortLandmark(pickupName);
  String get shortDrop => shortLandmark(dropName);
}

/// "Foody Street Campus Boulevard" → "Foody Street".
String shortLandmark(String name) {
  final cut = name.split(RegExp(r' \(| & | Campus| Men|, | Ground')).first;
  return cut.length > 22 ? '${cut.substring(0, 20)}…' : cut;
}

/// Route estimate from POST /api/map/route-calculate.
class RouteEstimate {
  const RouteEstimate({
    required this.distanceMeters,
    required this.walkMinutes,
    required this.queueMinutes,
    required this.detourMeters,
  });

  factory RouteEstimate.fromJson(Map<String, dynamic> j) => RouteEstimate(
    distanceMeters: _int(j['distanceMeters']),
    walkMinutes: _int(j['estimatedWalkMinutes']),
    queueMinutes: _int(j['queueTimeMinutes']),
    detourMeters: _num(j['detourMeters']),
  );

  final int distanceMeters;
  final int walkMinutes;
  final int queueMinutes;
  final double detourMeters;

  int get etaMinutes => walkMinutes + queueMinutes;
}

/// Token pack shown on "Buy Tokens" (prices from Figma frame 125:253).
class TokenPack {
  const TokenPack({
    required this.tokens,
    required this.priceInr,
    this.savePercent,
    this.popular = false,
  });

  final int tokens;
  final int priceInr;
  final int? savePercent;
  final bool popular;

  double get perToken => priceInr / tokens;

  static const all = [
    TokenPack(tokens: 50, priceInr: 100),
    TokenPack(tokens: 100, priceInr: 190, savePercent: 5),
    TokenPack(tokens: 250, priceInr: 450, savePercent: 10),
    TokenPack(tokens: 500, priceInr: 800, savePercent: 20, popular: true),
    TokenPack(tokens: 1000, priceInr: 1500, savePercent: 25),
  ];

  /// GST shown on "Confirm Purchase".
  static const gstRate = 0.18;
  int get gstInr => (priceInr * gstRate).round();
  int get totalInr => priceInr + gstInr;
}
