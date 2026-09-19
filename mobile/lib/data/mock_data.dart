import '../models/order_model.dart';

/// Local seed data. The app makes no network calls.
class MockData {
  MockData._();

  static const String defaultPickup = '742 Evergreen Terrace, Sector 4';
  static const String defaultDestination = 'Cyber Gateway Tower B, Hub 9';

  /// The courier shown to senders when their request is accepted.
  static const String courierName = 'Marcus Vance';
  static const String courierShortName = 'Marcus V.';

  static const String cancelReason = 'Courier vehicle issue / flat tire';

  static const List<String> savedAddresses = [
    defaultPickup,
    defaultDestination,
    'Green Glen Heights, Tower 2, Bellandur',
    'Prestige Tech Park IV, Marathahalli',
    'Bluestone Roasters, Koramangala 4th Block',
    'Indiranagar 100ft Road, Metro Gate 2',
    'Phoenix Marketcity, Whitefield',
  ];

  static List<DeliveryRequest> feed() {
    final now = DateTime.now();
    return [
      DeliveryRequest(
        id: 'REQ-801',
        pickup: defaultPickup,
        destination: defaultDestination,
        parcel: ParcelType.small,
        fare: 120,
        distanceKm: 4.8,
        etaMinutes: 18,
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
      DeliveryRequest(
        id: 'REQ-811',
        pickup: 'Main Gate',
        pickupDetail: 'Food · 1-2 items',
        destination: 'F Block',
        destinationDetail: 'Academic Block',
        parcel: ParcelType.medium,
        fare: 30,
        distanceKm: 1.1,
        etaMinutes: 6,
        detourMinutes: 7,
        createdAt: now.subtract(const Duration(minutes: 4)),
      ),
      DeliveryRequest(
        id: 'REQ-812',
        pickup: 'Food Court',
        pickupDetail: 'Snacks · 1 item',
        destination: 'Hostel 3',
        destinationDetail: 'Residential Block',
        parcel: ParcelType.small,
        fare: 40,
        distanceKm: 0.6,
        etaMinutes: 4,
        detourMinutes: 4,
        createdAt: now.subtract(const Duration(minutes: 6)),
      ),
      DeliveryRequest(
        id: 'REQ-802',
        pickup: 'Prestige Tech Park IV, Marathahalli',
        destination: 'Green Glen Heights, Tower 2, Bellandur',
        parcel: ParcelType.documents,
        fare: 95,
        distanceKm: 2.1,
        etaMinutes: 9,
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),
      DeliveryRequest(
        id: 'REQ-803',
        pickup: 'Bluestone Roasters, Koramangala 4th Block',
        destination: 'Phoenix Marketcity, Whitefield',
        parcel: ParcelType.medium,
        fare: 180,
        distanceKm: 6.4,
        etaMinutes: 22,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      DeliveryRequest(
        id: 'REQ-804',
        pickup: 'Indiranagar 100ft Road, Metro Gate 2',
        destination: 'Bluestone Roasters, Koramangala 4th Block',
        parcel: ParcelType.small,
        fare: 160,
        distanceKm: 2.7,
        etaMinutes: 11,
        createdAt: now.subtract(const Duration(minutes: 21)),
      ),
    ];
  }

  static List<DeliveryRequest> senderHistory() {
    final now = DateTime.now();
    return [
      DeliveryRequest(
        id: 'REQ-790',
        pickup: 'Indiranagar 100ft Road, Metro Gate 2',
        destination: defaultDestination,
        parcel: ParcelType.documents,
        fare: 100,
        distanceKm: 4.5,
        etaMinutes: 16,
        status: DeliveryStatus.delivered,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      DeliveryRequest(
        id: 'REQ-765',
        pickup: defaultPickup,
        destination: 'Bluestone Roasters, Koramangala 4th Block',
        parcel: ParcelType.small,
        fare: 125,
        distanceKm: 3.2,
        etaMinutes: 12,
        status: DeliveryStatus.delivered,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
