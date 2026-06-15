import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tite/main.dart';
import 'package:tite/spotify_home.dart';

void main() {
  testWidgets('Spotitan home smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Spotitan());

    // Verify that the home page is shown and brand name is correct.
    expect(find.text('Spotitan'), findsOneWidget);
    expect(find.text('Welcome to Spotitan'), findsOneWidget);
    
    // Check if side nav items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });
}
