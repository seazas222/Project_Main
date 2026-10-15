import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('the app opens the welcome screen from the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantApp());

    expect(find.text('Reserve • Order • Enjoy'), findsOneWidget);
    expect(find.text('Welcome to'), findsNothing);

    await tester.tap(find.byIcon(Icons.touch_app_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
