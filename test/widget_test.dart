import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// --- FIX: Import from 'sage', not 'myapp' ---
import 'package:sage/main.dart'; 

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // --- FIX: Use SageApp() instead of MyApp() ---
    await tester.pumpWidget(const SageApp()); 

    // Simple verification that the app builds
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
