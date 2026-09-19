import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:omw_delivery/main.dart';
import 'package:omw_delivery/models/order_model.dart';
import 'package:omw_delivery/screens/splash_screen.dart';
import 'package:omw_delivery/state/app_state.dart';

Widget _app(AppState state) =>
    ChangeNotifierProvider.value(value: state, child: const OmwApp());

/// Loads the bundled Inter weights so layout matches the device.
Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final w in [
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/inter/Inter-$w.ttf'));
  }
  await loader.load();
}

/// Figma frames are 375pt wide; test on a comparable phone viewport.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(_loadInter);

  testWidgets('splash falls back to the still wordmark and advances', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final state = AppState();
    await tester.pumpWidget(_app(state));
    await tester.pump(SplashScreen.maxDuration);
    await tester.pumpAndSettle();

    expect(state.stage, AppStage.signIn);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('email sign-in validates and opens the landing', (tester) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(state.stage, AppStage.signIn);

    await tester.enterText(find.byType(TextFormField), 'rohan@omw.app');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(state.stage, AppStage.landing);
    expect(find.text('OnMyWay'), findsOneWidget);
    expect(find.text('GOOD FOOD. LESS WAIT.'), findsOneWidget);
  });

  testWidgets('landing routes to both shells and back', (tester) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn)..signIn('a@b.co');
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ORDER'));
    await tester.pumpAndSettle();
    expect(state.role, AppRole.sender);
    expect(find.text('FAST COURIER MATCH'), findsOneWidget);
    expect(find.text('Delivery source'), findsOneWidget);

    await tester.tap(find.byTooltip('OnMyWay home'));
    await tester.pumpAndSettle();
    expect(state.stage, AppStage.landing);

    await tester.tap(find.text('DELIVER'));
    await tester.pumpAndSettle();
    expect(state.role, AppRole.courier);
    expect(find.text('All Deliveries'), findsOneWidget);

    await tester.tap(find.byTooltip('OnMyWay home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(state.senderTab, SenderTab.activity);
    expect(find.text('Your deliveries'), findsOneWidget);
  });

  testWidgets('offer price edits inline and delivery sources toggle', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn)
      ..signIn('a@b.co')
      ..enterAs(AppRole.sender);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    final price = find.widgetWithText(TextField, '120');
    await tester.enterText(price, '10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Minimum offer is ₹30'), findsOneWidget);
    expect(state.offer, 120);

    await tester.enterText(find.byType(TextField).first, '175');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.offer, 175);

    final quick = find.text('Quick Commerce');
    await tester.scrollUntilVisible(
      quick,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(state.sources, {DeliverySource.quickCommerce});

    await tester.tap(find.text('Delivery source'));
    await tester.pumpAndSettle();
    expect(find.text('Quick Commerce'), findsNothing);
  });

  testWidgets('sender picks parcel, offer validates, and broadcasts', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn)
      ..signIn('a@b.co')
      ..enterAs(AppRole.sender);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medium Box'));
    await tester.pumpAndSettle();
    expect(state.parcel, ParcelType.medium);
    expect(state.offer, ParcelType.medium.suggestedFare);

    expect(state.setOffer('10'), isNotNull);
    expect(state.setOffer('150'), isNull);
    await tester.pumpAndSettle();
    final cta = find.text('Broadcast Delivery Request for ₹150');
    await tester.scrollUntilVisible(
      cta,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(cta, findsOneWidget);
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();

    final before = state.history.length;
    await tester.tap(cta);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(state.history.length, before + 1);
    expect(find.text('Request broadcast'), findsOneWidget);

    await tester.tap(find.text('View activity'));
    await tester.pumpAndSettle();
    expect(state.senderTab, SenderTab.activity);
    expect(find.text('Your deliveries'), findsOneWidget);
  });

  testWidgets('courier feed filters and accepts requests', (tester) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn)
      ..signIn('a@b.co')
      ..enterAs(AppRole.courier);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    expect(find.text('All Deliveries'), findsOneWidget);
    expect(find.text('REQUEST FOR MATCH'), findsWidgets);
    expect(find.text('SLIGHT DETOUR'), findsWidgets);

    // Compact detour card accepts too.
    final detour = state.visibleFeed.firstWhere((r) => r.isDetour);
    await tester.tap(find.text('ACCEPT').first);
    await tester.pumpAndSettle();
    expect(state.accepted.first.id, detour.id);
    // Courier confirmation sheet; not the sender's own order, so no notice.
    expect(find.text('Delivery Accepted!'), findsOneWidget);
    expect(state.pendingNotice, isNull);
    await tester.tap(find.text('Back to Feed'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('High Fare (>150)'));
    await tester.pumpAndSettle();
    expect(state.visibleFeed.every((r) => r.fare > 150), isTrue);

    final first = state.visibleFeed.first;
    final accept = find.text('Accept Delivery Request for ₹${first.fare}');
    // Last Scrollable is the vertical feed (the first is the pill row).
    await tester.scrollUntilVisible(
      accept,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(state.accepted.first.id, first.id);
    expect(state.visibleFeed.any((r) => r.id == first.id), isFalse);
  });

  testWidgets('courier accept notifies the sender; tracking and dismiss', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn)
      ..signIn('a@b.co')
      ..enterAs(AppRole.sender);
    // Real timers: broadcast() waits 600 ms.
    final mine = await tester.runAsync(state.broadcast);
    state.enterAs(AppRole.courier);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    // Courier accepts the sender's request (top of the feed).
    // The sender's request is newest, so it is first in the feed.
    await tester.tap(
      find.text('Accept Delivery Request for ₹${mine!.fare}').first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Delivery Accepted!'), findsOneWidget);
    expect(
      find.text('Head to pickup. The sender has been notified.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to Feed'));
    await tester.pumpAndSettle();

    // Sender sees "Order Accepted!" as soon as the sender shell shows.
    state.enterAs(AppRole.sender);
    await tester.pumpAndSettle();
    expect(find.text('Order Accepted!'), findsOneWidget);
    expect(find.text('ORDER #${mine.id}'), findsOneWidget);

    await tester.tap(find.text('View Live Tracking'));
    await tester.pumpAndSettle();
    expect(state.pendingNotice, isNull);
    expect(find.text('On the way to Pickup'), findsOneWidget);
    expect(find.text('Order ID: #${mine.id}'), findsOneWidget);

    await tester.tap(find.text('View Order Details'));
    await tester.pumpAndSettle();
    expect(state.senderTab, SenderTab.activity);
    expect(find.text('On the way to Pickup'), findsNothing);
  });

  testWidgets('courier cancel shows Order Cancelled; dismiss by scrim', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final state = AppState(initialStage: AppStage.signIn)
      ..signIn('a@b.co')
      ..enterAs(AppRole.sender);
    // Real timers: broadcast() waits 600 ms.
    final mine = await tester.runAsync(state.broadcast);
    state.enterAs(AppRole.courier);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    // The sender's request is newest, so it is first in the feed.
    await tester.tap(
      find.text('Accept Delivery Request for ₹${mine!.fare}').first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel Job'));
    await tester.pumpAndSettle();
    expect(state.accepted, isEmpty);
    expect(state.visibleFeed.first.id, mine.id);

    state.enterAs(AppRole.sender);
    await tester.pumpAndSettle();
    // The stale "accepted" notice was replaced by the cancellation.
    expect(find.text('Order Accepted!'), findsNothing);
    expect(find.text('Order Cancelled'), findsOneWidget);
    expect(find.text('Courier vehicle issue / flat tire'), findsOneWidget);

    // Tap the dimmed overlay above the sheet to dismiss.
    await tester.tapAt(const Offset(187, 40));
    await tester.pumpAndSettle();
    expect(find.text('Order Cancelled'), findsNothing);
    expect(state.pendingNotice, isNull);
  });
}
