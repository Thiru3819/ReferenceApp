import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/main.dart';

void main() {
  testWidgets('generates a queue number from the registration form', (WidgetTester tester) async {
    await tester.pumpWidget(const TempleQueueApp());

    await tester.tap(find.byKey(const ValueKey('nav_user_registration')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('registration_name')), 'Suresh');
    await tester.enterText(find.byKey(const ValueKey('registration_phone')), '9876543210');

    await tester.ensureVisible(find.byKey(const ValueKey('register_submit')));
    await tester.tap(find.byKey(const ValueKey('register_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Your temple pass'), findsOneWidget);
    expect(find.text('Q-001'), findsWidgets);
    expect(find.text('Suresh'), findsWidgets);
    expect(find.text('Q-001-01'), findsWidgets);
    expect(find.text('Q-001-02'), findsWidgets);
  });

  testWidgets('logs a temple member in with username and password', (WidgetTester tester) async {
    await tester.pumpWidget(const TempleQueueApp());

    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav_temple_members')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('member_username')), 'arun');
    await tester.enterText(find.byKey(const ValueKey('member_password')), 'arun@111');
    await tester.ensureVisible(find.text('Login to temple dashboard'));
    await tester.tap(find.text('Login to temple dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Member dashboard'), findsWidgets);
    expect(find.text('Queue status chart'), findsOneWidget);
    expect(find.text('Arun'), findsWidgets);
  });
}
