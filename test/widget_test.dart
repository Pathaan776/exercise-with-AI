import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitcheck/config/di/injection.dart';
import 'package:fitcheck/config/theme/theme_cubit.dart';
import 'package:fitcheck/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  tearDown(() => getIt.reset());

  testWidgets('shell opens on Home with all three tabs', (tester) async {
    await tester.pumpWidget(const FitCheckApp());
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('every exercise is listed on the Train tab', (tester) async {
    await tester.pumpWidget(const FitCheckApp());
    await tester.pump();

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();

    expect(find.text('Squats'), findsOneWidget);
    expect(find.text('Push-ups'), findsOneWidget);

    // The third card sits below the fold at the default test viewport size.
    await tester.dragUntilVisible(
      find.text('Plank'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Plank'), findsOneWidget);
  });

  testWidgets('dark mode switch in Profile flips the theme', (tester) async {
    await tester.pumpWidget(const FitCheckApp());
    await tester.pump();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(getIt<ThemeCubit>().state.mode, ThemeMode.system);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(getIt<ThemeCubit>().state.mode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('accent choice survives a restart', (tester) async {
    await tester.pumpWidget(const FitCheckApp());
    await tester.pump();

    await getIt<ThemeCubit>().setMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    // Rebuild the object graph from the same backing store, as a cold start
    // would.
    await getIt.reset();
    await configureDependencies();

    expect(getIt<ThemeCubit>().state.mode, ThemeMode.dark);
  });
}
