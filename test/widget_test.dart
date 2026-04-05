// Basic widget smoke test. The full app boots with async Firebase + flutter_translate
// in lib/main.dart; those are covered by integration/manual tests instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp renders placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('SyncView'),
          ),
        ),
      ),
    );

    expect(find.text('SyncView'), findsOneWidget);
  });
}
