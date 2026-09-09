import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sansgato/widgets/feed_skeleton_loader.dart';

void main() {
  testWidgets('FeedSkeletonLoader renders correctly in light mode', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FeedSkeletonLoader(isDark: false))));
    
    expect(find.byType(ListView), findsOneWidget);
  });
}
