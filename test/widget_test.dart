import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/main.dart';

void main() {
  testWidgets('DivineQueueApp loads correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DivineQueueApp());
    await tester.pumpAndSettle();

    expect(find.text('DivineQueue'), findsOneWidget);
  });
}
