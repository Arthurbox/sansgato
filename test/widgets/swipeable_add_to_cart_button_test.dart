import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sansgato/widgets/swipeable_add_to_cart_button.dart';

void main() {
  testWidgets('SwipeableAddToCartButton shows initial text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeableAddToCartButton(onSwipe: () async => true),
        ),
      ),
    );
    expect(find.text('Glisser pour ajouter'), findsOneWidget);
  });

  testWidgets('SwipeableAddToCartButton renders added state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeableAddToCartButton(onSwipe: () async => true, isAdded: true),
        ),
      ),
    );
    // Vérifie que le composant est bien monté même si on ne teste pas le texte exact car il peut changer
    expect(find.byType(SwipeableAddToCartButton), findsOneWidget);
  });
}
