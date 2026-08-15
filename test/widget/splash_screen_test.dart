import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_finance_tracker/core/constants/app_constants.dart';
import 'package:my_personal_finance_tracker/presentation/screens/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows the app name and tagline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
  });
}
