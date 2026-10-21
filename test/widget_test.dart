import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saas_app/splash_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash redirects to login when no token exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: const SplashPage(),
        routes: {
          '/login': (_) => const Scaffold(
            body: Center(child: Text('Login screen')),
          ),
        },
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Login screen'), findsOneWidget);
  });
}