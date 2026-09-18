enum AppMode {
  order,
  deliver,
}

enum ScreenType {
  order,
  tracking,
  feed,
  pending,
  account,
}

enum ParcelType {
  documents,
  small,
  medium,
}

extension ParcelTypeExtension on ParcelType {
  String get label {
    switch (this) {
      case ParcelType.documents:
        return 'Documents';
      case ParcelType.small:
        return 'Small Box';
      case ParcelType.medium:
        return 'Medium Box';
    }
  }

  String get weightSub {
    switch (this) {
      case ParcelType.documents:
        return '< 0.5 kg';
      case ParcelType.small:
        return '< 2 kg';
      case ParcelType.medium:
        return 'Up to 5 kg';
    }
  }

  String get iconAsset {
    switch (this) {
      case ParcelType.documents:
        return 'assets/caf91.svg';
      case ParcelType.small:
        return 'assets/e5957.svg';
      case ParcelType.medium:
        return 'assets/067ec.svg';
    }
  }
}

class PendingOrder {
  final String id;
  final String pickup;
  final String dropoff;
  final ParcelType parcelType;
  int offerPrice;
  final DateTime broadcastTime;
  final String windowLabel;
  bool accepted;
  int? acceptedPrice;
  bool countered;
  int stage;
  String courierName;
  String vehicleNo;
  double distanceKm;

  PendingOrder({
    required this.id,
    required this.pickup,
    required this.dropoff,
    required this.parcelType,
    required this.offerPrice,
    required this.broadcastTime,
    required this.windowLabel,
    this.accepted = false,
    this.acceptedPrice,
    this.countered = false,
    this.stage = 1,
    this.courierName = 'Aarav Sharma',
    this.vehicleNo = 'KA 01 EQ 4920',
    this.distanceKm = 4.8,
  });

  PendingOrder copyWith({
    String? id,
    String? pickup,
    String? dropoff,
    ParcelType? parcelType,
    int? offerPrice,
    DateTime? broadcastTime,
    String? windowLabel,
    bool? accepted,
    int? acceptedPrice,
    bool? countered,
    int? stage,
    String? courierName,
    String? vehicleNo,
    double? distanceKm,
  }) {
    return PendingOrder(
      id: id ?? this.id,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      parcelType: parcelType ?? this.parcelType,
      offerPrice: offerPrice ?? this.offerPrice,
      broadcastTime: broadcastTime ?? this.broadcastTime,
      windowLabel: windowLabel ?? this.windowLabel,
      accepted: accepted ?? this.accepted,
      acceptedPrice: acceptedPrice ?? this.acceptedPrice,
      countered: countered ?? this.countered,
      stage: stage ?? this.stage,
      courierName: courierName ?? this.courierName,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class Hotspot {
  final String id;
  final String title;
  final String area;
  final String city;
  final String tag;
  final double distanceKm;

  const Hotspot({
    required this.id,
    required this.title,
    required this.area,
    required this.city,
    required this.tag,
    required this.distanceKm,
  });
}

const List<Hotspot> popularHotspots = [
  Hotspot(
    id: '1',
    title: '742 Evergreen Terrace, Sector 4',
    area: 'HSR Layout',
    city: 'Bengaluru',
    tag: 'residential',
    distanceKm: 2.4,
  ),
  Hotspot(
    id: '2',
    title: 'Cyber Gateway Tower B, Hub 9',
    area: 'Bellandur ORR',
    city: 'Bengaluru',
    tag: 'office',
    distanceKm: 4.8,
  ),
  Hotspot(
    id: '3',
    title: 'Bluestone Cafe & Roasters',
    area: 'Koramangala 4th Block, 80ft Rd',
    city: 'Bengaluru',
    tag: 'popular',
    distanceKm: 3.1,
  ),
  Hotspot(
    id: '4',
    title: 'Green Glen Heights, Apt 402',
    area: 'Bellandur',
    city: 'Bengaluru',
    tag: 'residential',
    distanceKm: 5.2,
  ),
  Hotspot(
    id: '5',
    title: 'Indiranagar Metro Station Gate 2',
    area: '100ft Road, Indiranagar',
    city: 'Bengaluru',
    tag: 'metro',
    distanceKm: 6.5,
  ),
  Hotspot(
    id: '6',
    title: 'Prestige Tech Park IV',
    area: 'Marathahalli - Sarjapur ORR',
    city: 'Bengaluru',
    tag: 'office',
    distanceKm: 7.2,
  ),
  Hotspot(
    id: '7',
    title: 'Phoenix Marketcity Main Entrance',
    area: 'Whitefield Main Rd',
    city: 'Bengaluru',
    tag: 'popular',
    distanceKm: 12.0,
  ),
  Hotspot(
    id: '8',
    title: 'Church Street Social & Bookstores',
    area: 'MG Road / Brigade Rd',
    city: 'Bengaluru',
    tag: 'popular',
    distanceKm: 8.4,
  ),
];

class ChatMessage {
  final String id;
  final String sender; // 'user' or 'courier'
  final String text;
  final String time;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
  });
}
