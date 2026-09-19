import '../theme/app_icons.dart';
import 'omw_models.dart';

/// Which side of the marketplace the signed-in user is acting as.
enum AppRole { sender, courier }

/// Sender tab bar (Figma "account" / "wallet-and-earnings" frames).
enum SenderTab { home, activity, wallet, account }

/// Courier tab bar (Figma "runner-feed" frame).
enum CourierTab { feed, activity, earnings, account }

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

  /// Category stored on the backend task.
  String get category => switch (this) {
    ParcelType.documents => 'documents',
    ParcelType.small => 'small',
    ParcelType.medium => 'medium',
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

/// Filter pills on the runner feed.
enum RunnerFilter { alongRoute, nearby, all }

extension RunnerFilterX on RunnerFilter {
  String get label => switch (this) {
    RunnerFilter.alongRoute => 'Along my route',
    RunnerFilter.nearby => 'Nearby',
    RunnerFilter.all => 'All',
  };
}

/// How well a task fits the runner's active route.
enum RouteFit { perfect, near, detour }

extension RouteFitX on RouteFit {
  String get eyebrow => switch (this) {
    RouteFit.perfect => 'PERFECT FOR YOUR ROUTE',
    RouteFit.near => 'NEAR YOUR ROUTE',
    RouteFit.detour => 'SLIGHT DETOUR',
  };
}

/// Kinds of in-app notification (sheets + the Notifications list).
enum NoticeKind {
  /// Sender: a courier claimed the request (Figma 164:116).
  accepted,

  /// Sender: pickup OTP verified (Figma 164:267 "Package Secured").
  pickedUp,

  /// Sender: courier is at the drop-off (Figma 163:182).
  arrived,

  /// Sender: delivery OTP verified.
  delivered,

  /// Sender: the courier dropped the job (Figma 163:76).
  cancelledByCourier,

  /// Courier: a new request near the active route (Figma 163:129).
  alongRoute,
}

class AppNotice {
  AppNotice({
    required this.kind,
    required this.task,
    DateTime? at,
    this.detourKm,
    this.detourMinutes,
  }) : at = at ?? DateTime.now(),
       id = '${kind.name}-${task.id}-${DateTime.now().microsecondsSinceEpoch}';

  final String id;
  final NoticeKind kind;
  final OmwTask task;
  final DateTime at;
  final double? detourKm;
  final int? detourMinutes;

  String get title => switch (kind) {
    NoticeKind.accepted => 'Courier Assigned!',
    NoticeKind.pickedUp => 'Package Secured',
    NoticeKind.arrived => 'Delivery Arrived!',
    NoticeKind.delivered => 'Delivered',
    NoticeKind.cancelledByCourier => 'Delivery Cancelled',
    NoticeKind.alongRoute => 'Along-Your-Route!',
  };

  String get body {
    final runner = task.runnerName ?? 'Your courier';
    return switch (kind) {
      NoticeKind.accepted =>
        '$runner is en route to pick up your order at ${task.shortPickup}.',
      NoticeKind.pickedUp => '$runner has successfully picked up your item.',
      NoticeKind.arrived => '$runner is outside with your package.',
      NoticeKind.delivered =>
        'Your ${task.parcel.label.toLowerCase()} reached ${task.shortDrop}.',
      NoticeKind.cancelledByCourier =>
        'Your courier dropped the job. We are looking for a new partner.',
      NoticeKind.alongRoute =>
        'New request at ${task.shortPickup} for ₹${task.wager}.',
    };
  }
}
