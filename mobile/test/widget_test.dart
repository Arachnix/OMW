import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:omw_delivery/main.dart';
import 'package:omw_delivery/state/app_state.dart';

void main() {
  testWidgets('Sign in screen renders and validates credentials',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const OmwApp(),
      ),
    );

    // Initial screen checks
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);

    // Test empty validation
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Please enter your email address.'), findsOneWidget);

    // Test invalid credentials
    await tester.enterText(
        find.widgetWithText(TextField, 'email@domain.com'), 'wrong@gmail.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'wrongpass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Incorrect email or password.'), findsOneWidget);

    // Test valid credentials (dev@gmail.com / dev)
    await tester.enterText(
        find.widgetWithText(TextField, 'email@domain.com'), 'dev@gmail.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'dev');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    // Verifies navigation to Home screen
    expect(find.text('Welcome to OMW!'), findsOneWidget);
    expect(find.text('Signed in as dev@gmail.com'), findsOneWidget);
  });
}
