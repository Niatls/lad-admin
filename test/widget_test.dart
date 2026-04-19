// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lad_admin/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launch and login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LadAdminApp()));

    // Wait for the initial redirect to /login to happen
    await tester.pumpAndSettle();

    // Verify that the login screen is present by checking for the app title
    expect(find.text('Lad Admin'), findsOneWidget);
    // Verify that the login button is present
    expect(find.text('Войти'), findsOneWidget);
    // Verify that the dashboard is not present yet (since we are not logged in)
    expect(find.text('Дашборд'), findsNothing);
  });
}
