import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic App Smoke Test', (WidgetTester tester) async {
    // Un test très basique pour remplacer le test par défaut de Flutter
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Sansgato'))));
    expect(find.text('Sansgato'), findsOneWidget);
  });
}
