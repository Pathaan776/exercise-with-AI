import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:fitcheck/features/workout/domain/analyzers/exercise_analyzer.dart';
import 'package:fitcheck/features/workout/domain/analyzers/plank_analyzer.dart';
import 'package:fitcheck/features/workout/domain/analyzers/pushup_analyzer.dart';
import 'package:fitcheck/features/workout/domain/analyzers/squat_analyzer.dart';
import 'package:fitcheck/features/workout/domain/entities/exercise_analysis.dart';

import 'pose_fixtures.dart';

/// Angles are smoothed across frames, so a position only registers once
/// enough frames have been fed at it — exactly as in a live session.
ExerciseAnalysis _hold(
  ExerciseAnalyzer analyzer,
  Pose pose, {
  int frames = 25,
  DateTime? start,
  Duration step = const Duration(milliseconds: 40),
}) {
  late ExerciseAnalysis result;
  for (var i = 0; i < frames; i++) {
    result = analyzer.analyzeFrame([pose], now: start?.add(step * i));
  }
  return result;
}

void main() {
  group('SquatAnalyzer', () {
    test('counts a deep, upright rep as correct', () {
      final analyzer = SquatAnalyzer();

      _hold(analyzer, squatPose(kneeAngle: 178));
      final bottom = _hold(analyzer, squatPose(kneeAngle: 85));
      expect(bottom.phase, ExercisePhase.down);
      expect(bottom.repsCorrect, 0, reason: 'rep only lands on the way up');

      final top = _hold(analyzer, squatPose(kneeAngle: 175));
      expect(top.repsCorrect, 1);
      expect(top.repsWrong, 0);
      expect(top.phase, ExercisePhase.up);
    });

    test('marks a deep rep with a collapsed torso as wrong', () {
      final analyzer = SquatAnalyzer();

      _hold(analyzer, squatPose(kneeAngle: 178));
      _hold(analyzer, squatPose(kneeAngle: 85, torsoLean: 75));
      final top = _hold(analyzer, squatPose(kneeAngle: 175, torsoLean: 75));

      expect(top.repsWrong, 1);
      expect(top.repsCorrect, 0);
    });

    test('does not count a rep that never reaches depth', () {
      final analyzer = SquatAnalyzer();

      _hold(analyzer, squatPose(kneeAngle: 178));
      _hold(analyzer, squatPose(kneeAngle: 140));
      final top = _hold(analyzer, squatPose(kneeAngle: 175));

      expect(top.totalReps, 0);
      expect(top.coachingTip, isNull);
    });

    test('reports no person when landmarks are not confident', () {
      final analyzer = SquatAnalyzer();
      final result = analyzer.analyzeFrame([
        squatPose(kneeAngle: 90, likelihood: 0.2),
      ]);

      expect(result.hasPerson, isFalse);
      expect(result.angles, isEmpty);
    });

    test('reset clears the rep count', () {
      final analyzer = SquatAnalyzer();

      _hold(analyzer, squatPose(kneeAngle: 178));
      _hold(analyzer, squatPose(kneeAngle: 85));
      expect(_hold(analyzer, squatPose(kneeAngle: 175)).repsCorrect, 1);

      analyzer.reset();
      expect(analyzer.analyzeFrame([squatPose(kneeAngle: 178)]).repsCorrect, 0);
    });

    test('a still image is scored without counting reps', () {
      final analyzer = SquatAnalyzer();
      final result = analyzer.analyzeStill([squatPose(kneeAngle: 88)]);

      expect(result.hasPerson, isTrue);
      expect(result.inPosition, isTrue);
      expect(result.isCorrectForm, isTrue);
      expect(result.totalReps, 0);
    });
  });

  group('PushupAnalyzer', () {
    test('counts a full-depth rep with a straight body as correct', () {
      final analyzer = PushupAnalyzer();

      _hold(analyzer, pushupPose(elbowAngle: 172));
      _hold(analyzer, pushupPose(elbowAngle: 80));
      final top = _hold(analyzer, pushupPose(elbowAngle: 172));

      expect(top.repsCorrect, 1);
      expect(top.repsWrong, 0);
    });

    test('marks a rep performed with sagging hips as wrong', () {
      final analyzer = PushupAnalyzer();

      _hold(analyzer, pushupPose(elbowAngle: 172, hipSag: 110));
      _hold(analyzer, pushupPose(elbowAngle: 80, hipSag: 110));
      final top = _hold(analyzer, pushupPose(elbowAngle: 172, hipSag: 110));

      expect(top.repsWrong, 1);
      expect(top.repsCorrect, 0);
      expect(top.coachingTip, contains('core'));
    });

    test('does not count a half rep', () {
      final analyzer = PushupAnalyzer();

      _hold(analyzer, pushupPose(elbowAngle: 172));
      _hold(analyzer, pushupPose(elbowAngle: 130));
      final top = _hold(analyzer, pushupPose(elbowAngle: 172));

      expect(top.totalReps, 0);
    });
  });

  group('PlankAnalyzer', () {
    final start = DateTime(2026, 1, 1, 9);

    test('accumulates hold time while the body stays straight', () {
      final analyzer = PlankAnalyzer();

      final result = _hold(
        analyzer,
        plankPose(),
        frames: 11,
        start: start,
        step: const Duration(milliseconds: 500),
      );

      expect(result.phase, ExercisePhase.holding);
      expect(result.holdSeconds, 5);
      expect(result.isCorrectForm, isTrue);
    });

    test('drops the timer once the hips sag past the grace window', () {
      final analyzer = PlankAnalyzer();

      _hold(
        analyzer,
        plankPose(),
        frames: 11,
        start: start,
        step: const Duration(milliseconds: 500),
      );

      final broken = _hold(
        analyzer,
        plankPose(hipSag: 110),
        frames: 10,
        start: start.add(const Duration(seconds: 5)),
        step: const Duration(milliseconds: 400),
      );

      expect(broken.phase, ExercisePhase.idle);
      expect(broken.holdSeconds, 0);
      expect(
        broken.bestHoldSeconds,
        greaterThanOrEqualTo(5),
        reason: 'the best hold is kept after the timer resets',
      );
      expect(broken.coachingTip, contains('Hips'));
    });

    test('standing upright never starts the timer', () {
      final analyzer = PlankAnalyzer();

      final result = _hold(
        analyzer,
        standingPose(),
        frames: 11,
        start: start,
        step: const Duration(milliseconds: 500),
      );

      expect(result.hasPerson, isTrue);
      expect(result.inPosition, isFalse);
      expect(result.phase, ExercisePhase.idle);
      expect(result.holdSeconds, 0);
    });

    test('a brief wobble inside the grace window keeps the hold alive', () {
      final analyzer = PlankAnalyzer();

      _hold(
        analyzer,
        plankPose(),
        frames: 11,
        start: start,
        step: const Duration(milliseconds: 500),
      );

      // One frame off-line, then straight again — well under the 900ms grace.
      analyzer.analyzeFrame([
        plankPose(hipSag: 110),
      ], now: start.add(const Duration(seconds: 5, milliseconds: 100)));
      final recovered = analyzer.analyzeFrame([
        plankPose(),
      ], now: start.add(const Duration(seconds: 5, milliseconds: 300)));

      expect(recovered.holdSeconds, 5);
    });
  });
}
