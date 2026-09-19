import '../theme/app_icons.dart';

/// Which side of the marketplace the signed-in user is acting as.
enum AppRole { sender, courier }

enum SenderTab { home, activity, account }

enum CourierTab { feed, account }

enum ParcelType { documents, small, medium }

extension ParcelTypeX on ParcelType {
  String get label => switch (this) {
    ParcelType.documents => 'Documents',
    ParcelType.small => 'Small Box',
    ParcelType.medium => 'Medium Box',
  };

  String get weight => switch (this) {
    ParcelType.documents => '< 0.5 kg',
    ParcelType.small => '< 2 kg',
    ParcelType.medium => 'Up to 5 kg',
  };

  String get icon => switch (this) {
    ParcelType.documents => AppIcons.file,
    ParcelType.small => AppIcons.box,
    ParcelType.medium => AppIcons.package,
  };

  /// Suggested fare shown when the parcel type is picked.
  int get suggestedFare => switch (this) {
    ParcelType.documents => 80,
    ParcelType.small => 120,
    ParcelType.medium => 160,
  };
}

enum DeliveryStatus { broadcasted, accepted, delivered }

extension DeliveryStatusX on DeliveryStatus {
  String get label => switch (this) {
    DeliveryStatus.broadcasted => 'Looking for courier',
    DeliveryStatus.accepted => 'Courier on the way',
    DeliveryStatus.delivered => 'Delivered',
  };
}

/// Options in the sender's "Delivery source" dropdown.
enum DeliverySource { quickCommerce, eCommerce }

extension DeliverySourceX on DeliverySource {
  String get label => switch (this) {
    DeliverySource.quickCommerce => 'Quick Commerce',
    DeliverySource.eCommerce => 'E-Commerce',
  };
}

/// Filters from the "Pills" component on the delivery feed.
enum FeedFilter { all, highFare, nearby }

extension FeedFilterX on FeedFilter {
  String get label => switch (this) {
    FeedFilter.all => 'All Deliveries',
    FeedFilter.highFare => 'High Fare (>150)',
    FeedFilter.nearby => '< 3km',
  };

  bool matches(DeliveryRequest r) => switch (this) {
    FeedFilter.all => true,
    FeedFilter.highFare => r.fare > 150,
    FeedFilter.nearby => r.distanceKm < 3,
  };
}

class DeliveryRequest {
  const DeliveryRequest({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.parcel,
    required this.fare,
    required this.distanceKm,
    required this.etaMinutes,
    required this.createdAt,
    this.status = DeliveryStatus.broadcasted,
    this.sources = const {},
    this.pickupDetail,
    this.destinationDetail,
    this.detourMinutes,
  });

  final String id;
  final String pickup;
  final String destination;
  final ParcelType parcel;
  final int fare;
  final double distanceKm;
  final int etaMinutes;
  final DateTime createdAt;
  final DeliveryStatus status;
  final Set<DeliverySource> sources;

  /// Secondary line under the pickup, e.g. "Food · 1-2 items".
  final String? pickupDetail;

  /// Secondary line under the destination, e.g. "Academic Block".
  final String? destinationDetail;

  /// Extra minutes on the courier's current route. When set, the feed shows
  /// the compact "SLIGHT DETOUR" card (Figma "request-card-3").
  final int? detourMinutes;

  bool get isDetour => detourMinutes != null;

  DeliveryRequest copyWith({DeliveryStatus? status}) => DeliveryRequest(
    id: id,
    pickup: pickup,
    destination: destination,
    parcel: parcel,
    fare: fare,
    distanceKm: distanceKm,
    etaMinutes: etaMinutes,
    createdAt: createdAt,
    status: status ?? this.status,
    sources: sources,
    pickupDetail: pickupDetail,
    destinationDetail: destinationDetail,
    detourMinutes: detourMinutes,
  );
}

enum NoticeKind { accepted, cancelled }

/// In-app notification for the sender about one of their requests.
class SenderNotice {
  const SenderNotice({required this.kind, required this.request, this.reason});

  final NoticeKind kind;
  final DeliveryRequest request;

  /// Cancellation reason, for [NoticeKind.cancelled].
  final String? reason;
}
