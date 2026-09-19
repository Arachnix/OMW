import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:omw_delivery/main.dart';
import 'package:omw_delivery/models/omw_models.dart';
import 'package:omw_delivery/models/order_model.dart';
import 'package:omw_delivery/screens/runner/delivery_code_screen.dart';
import 'package:omw_delivery/screens/splash_screen.dart';
import 'package:omw_delivery/screens/wallet/withdraw_screen.dart';
import 'package:omw_delivery/state/app_state.dart';
import 'package:omw_delivery/state/session_store.dart';

import 'fake_api.dart';

Widget _app(AppState state) =>
    ChangeNotifierProvider.value(value: state, child: const OmwApp());

/// Loads the bundled fonts so layout matches the device.
Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in [
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black',
  ]) {
    inter.addFont(rootBundle.load('assets/fonts/inter/Inter-$w.ttf'));
  }
  await inter.load();
  await (FontLoader('ArchivoBlack')..addFont(
        rootBundle.load('assets/fonts/archivo_black/ArchivoBlack-Regular.ttf'),
      ))
      .load();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Signs in against the fake API and enters [role].
Future<(AppState, FakeOmwApi)> _signedIn(
  WidgetTester tester, {
  AppRole role = AppRole.sender,
  FakeOmwApi? api,
}) async {
  final fake = api ?? FakeOmwApi();
  final state = AppState(
    api: fake,
    session: MemorySessionStore(),
    initialStage: AppStage.signIn,
  );
  await state.signIn('vismay.shrouty@vitstudent.ac.in');
  await state.loadLocations();
  state.enterAs(role);
  await tester.pumpWidget(_app(state));
  await tester.pumpAndSettle();
  return (state, fake);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('splash advances to sign-in without a saved session', (
    tester,
  ) async {
    _phone(tester);
    final state = AppState(api: FakeOmwApi(), session: MemorySessionStore());
    await state.restoreSession();
    await tester.pumpWidget(_app(state));
    await tester.pump(SplashScreen.maxDuration);
    await tester.pumpAndSettle();
    expect(state.stage, AppStage.signIn);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('email sign-in validates, then logs in to the backend', (
    tester,
  ) async {
    _phone(tester);
    final state = AppState(
      api: FakeOmwApi(),
      session: MemorySessionStore(),
      initialStage: AppStage.signIn,
    );
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'nope');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'vismay.shrouty22@vitstudent.ac.in',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(state.stage, AppStage.landing);
    expect(state.user?.name, 'Vismay Shrouty');
    expect(find.text('GOOD FOOD. LESS WAIT.'), findsOneWidget);
  });

  testWidgets('sender broadcasts a request; escrow locks the offer', (
    tester,
  ) async {
    _phone(tester);
    final (state, fake) = await _signedIn(tester);
    expect(find.text('FAST COURIER MATCH'), findsOneWidget);
    expect(find.text('~8 mins'), findsOneWidget); // walk 6 + queue 2

    final cta = find.text('Broadcast Delivery Request for ₹20');
    await tester.scrollUntilVisible(
      cta,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('Request broadcast'), findsOneWidget);
    expect(state.myRequests, hasLength(1));
    expect(fake.escrow, 20);

    await tester.tap(find.text('View activity'));
    await tester.pumpAndSettle();
    expect(find.text('Pending Orders'), findsOneWidget);
    expect(find.text('Waiting for courier..'), findsOneWidget);
  });

  testWidgets('insufficient tokens offers to buy more', (tester) async {
    _phone(tester);
    await _signedIn(tester, api: FakeOmwApi(available: 5));
    final cta = find.text('Broadcast Delivery Request for ₹20');
    await tester.scrollUntilVisible(
      cta,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(find.text('Not enough tokens'), findsOneWidget);
  });

  testWidgets('live claim shows "Order Accepted!" and tracking', (
    tester,
  ) async {
    _phone(tester);
    final (state, fake) = await _signedIn(tester);
    final task = await state.broadcast();
    await tester.pumpAndSettle();

    fake.pushStatus(task.id, 'CLAIMED');
    await tester.pumpAndSettle();
    expect(find.text('Order Accepted!'), findsOneWidget);
    expect(
      find.text('Pickup partner Marcus Vance is on the way.'),
      findsOneWidget,
    );

    await tester.tap(find.text('View Live Tracking'));
    await tester.pumpAndSettle();
    expect(find.text('On the way to Pickup'), findsOneWidget);
    expect(find.text('Order ID: #${task.id}'), findsOneWidget);
    expect(state.pendingNotice, isNull);
  });

  testWidgets('courier accepts from the feed and confirms pickup', (
    tester,
  ) async {
    _phone(tester);
    final fake = FakeOmwApi();
    fake.seedOpenTask();
    final (state, _) = await _signedIn(
      tester,
      role: AppRole.courier,
      api: fake,
    );
    await state.refreshFeed();
    state.setFilter(RunnerFilter.all);
    await tester.pumpAndSettle();

    expect(find.text('Runner Mode'), findsOneWidget);
    final accept = find.text('ACCEPT').first;
    await tester.scrollUntilVisible(
      accept,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(find.text('Delivery Accepted!'), findsOneWidget);
    expect(fake.staked, 8); // 25% of 30

    await tester.tap(find.text('Start Delivery'));
    await tester.pumpAndSettle();
    expect(state.courierTab, CourierTab.activity);
    await tester.tap(find.text('Confirm Pickup'));
    await tester.pumpAndSettle();
    expect(find.text('1111'), findsOneWidget);
    await tester.tap(find.text('Parcel Collected'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Delivery Code'), findsOneWidget);
  });

  testWidgets('wrong delivery code shows the invalid state', (tester) async {
    _phone(tester);
    final fake = FakeOmwApi();
    final seeded = fake.seedOpenTask();
    final (state, _) = await _signedIn(
      tester,
      role: AppRole.courier,
      api: fake,
    );
    await state.refresh();
    final claimed = await state.claim(state.taskById(seeded.id)!);
    await state.confirmPickup(claimed, '1111');
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(Scaffold).first))
        .push(DeliveryCodeScreen.route(seeded.id));
    await tester.pumpAndSettle();
    expect(fake.sent.any((m) => m['type'] == 'RUNNER_ARRIVED'), isTrue);

    await tester.enterText(find.byType(TextField).first, '9025');
    await tester.pumpAndSettle();
    expect(find.text('Invalid Verification Code'), findsOneWidget);
    expect(find.textContaining('2 attempts remaining'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '2222');
    await tester.pumpAndSettle();
    expect(state.taskById(seeded.id)!.status, TaskStatus.delivered);
  });

  testWidgets('wallet: buy tokens end to end', (tester) async {
    _phone(tester);
    final (state, fake) = await _signedIn(tester);
    await state.setUpi('vismay@okaxis');
    state.setSenderTab(SenderTab.wallet);
    await tester.pumpAndSettle();
    expect(find.text('Wallet & Earnings'), findsOneWidget);
    expect(find.text('₹85'), findsWidgets);

    await tester.tap(find.text('Buy Tokens').first);
    await tester.pumpAndSettle();
    final buy = find.text('Buy 500 Tokens for ₹800');
    await tester.scrollUntilVisible(
      buy,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(find.text('Confirm Purchase'), findsOneWidget);
    expect(find.text('₹944'), findsOneWidget);

    await tester.tap(find.text('Pay ₹944'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Successful!'), findsOneWidget);
    expect(fake.available, 585);
    final toWallet = find.text('Go to Wallet');
    await tester.scrollUntilVisible(
      toWallet,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(toWallet);
    await tester.pumpAndSettle();
    expect(find.text('₹585'), findsWidgets);
  });

  testWidgets('withdraw flags amounts above the available balance', (
    tester,
  ) async {
    _phone(tester);
    final (state, _) = await _signedIn(tester);
    await state.setUpi('vismay@okaxis');
    Navigator.of(tester.element(find.byType(Scaffold).first))
        .push(WithdrawScreen.route());
    await tester.pumpAndSettle();
    // Default ₹500 > ₹85 available.
    expect(
      find.text('Amount exceeds your available balance of ₹85.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Max'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw ₹85'), findsOneWidget);
  });

  testWidgets('runner feed shows the network error state', (tester) async {
    _phone(tester);
    await _signedIn(
      tester,
      role: AppRole.courier,
      api: FakeOmwApi(failTasks: true),
    );
    expect(find.text('Failed to Load Feed'), findsOneWidget);
    expect(find.text('Retry Loading'), findsOneWidget);
  });

  testWidgets('account shows the profile and stats', (tester) async {
    _phone(tester);
    final (state, _) = await _signedIn(tester);
    state.setSenderTab(SenderTab.account);
    await tester.pumpAndSettle();
    expect(find.text('Vismay Shrouty'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    final logOut = find.text('Log Out');
    await tester.scrollUntilVisible(
      logOut,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(logOut, findsOneWidget);
  });
}
