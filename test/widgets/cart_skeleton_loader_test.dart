import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sansgato/widgets/cart_skeleton_loader.dart';

void main() {
  testWidgets('CartSkeletonLoader renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CartSkeletonLoader())));
    
    // Vérifie la présence du ListView généré par le squelette
    expect(find.byType(ListView), findsOneWidget);
  });
}
