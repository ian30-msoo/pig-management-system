import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mkulimaproo/main.dart';

void main() {
  testWidgets('MkulimaPro app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MkulimaProApp());

    // Verify the app renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}