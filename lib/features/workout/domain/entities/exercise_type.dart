import 'package:flutter/material.dart';

/// How an exercise is scored: by counting repetitions, or by holding a
/// position for as long as possible.
enum ScoringMode { reps, hold }

enum ExerciseType {
  squat(
    id: 'squat',
    label: 'Squats',
    tagline: 'Legs & glutes',
    description:
        'Stand side-on to the camera. Drive your hips back and down until '
        'your thighs are at least parallel to the floor, then stand tall.',
    icon: Icons.accessibility_new_rounded,
    scoring: ScoringMode.reps,
    trackedAngles: ['Knee', 'Hip'],
  ),
  pushup(
    id: 'pushup',
    label: 'Push-ups',
    tagline: 'Chest & triceps',
    description:
        'Film from the side. Keep a straight line from shoulders to ankles '
        'and lower until your elbows bend past 90°.',
    icon: Icons.fitness_center_rounded,
    scoring: ScoringMode.reps,
    trackedAngles: ['Elbow', 'Body'],
  ),
  plank(
    id: 'plank',
    label: 'Plank',
    tagline: 'Core stability',
    description:
        'Film from the side. Hold a straight line from shoulders through '
        'hips to ankles — no sagging, no piking.',
    icon: Icons.self_improvement_rounded,
    scoring: ScoringMode.hold,
    trackedAngles: ['Body', 'Hip'],
  );

  const ExerciseType({
    required this.id,
    required this.label,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.scoring,
    required this.trackedAngles,
  });

  final String id;
  final String label;
  final String tagline;
  final String description;
  final IconData icon;
  final ScoringMode scoring;
  final List<String> trackedAngles;

  bool get isHold => scoring == ScoringMode.hold;

  static ExerciseType fromId(String id) =>
      ExerciseType.values.firstWhere((e) => e.id == id);
}
