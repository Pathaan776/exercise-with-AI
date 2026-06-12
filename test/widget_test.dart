// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/main.dart';

void main() {
  testWidgets('App renders squats home', (WidgetTester tester) async {
    await getIt.reset();
    await configureDependencies();

    await tester.pumpWidget(const FitCheckApp());
    await tester.pump();

    expect(find.text('Pick Image (Gallery)'), findsOneWidget);
    expect(find.text('Live Camera (Realtime)'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
