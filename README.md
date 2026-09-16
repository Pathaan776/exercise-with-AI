# FitCheck

On-device exercise form coaching. FitCheck watches you through the camera,
tracks your joints with Google ML Kit pose detection, and grades each rep on
depth and body position — all locally. No video, photo or measurement ever
leaves the phone.

## What it does

| Exercise  | Scoring      | Graded on                                    |
| --------- | ------------ | -------------------------------------------- |
| Squats    | Rep counting | Knee depth, torso angle at the bottom         |
| Push-ups  | Rep counting | Elbow depth, shoulder→hip→ankle straightness  |
| Plank     | Timed hold   | Body straightness, hip sag or pike            |

Two ways to get feedback:

- **Live session** — full-screen camera with a skeleton overlay, running rep
  count, form score and one-line coaching corrections.
- **Photo check** — pick a still from the gallery to score a single position.

## Structure

```
lib/
  config/        theme (light + dark + accents), routing, DI
  core/          preferences, shared widgets
  features/
    shell/       bottom-nav scaffold
    home/        dashboard: daily goal, lifetime stats
    workout/     pose detection, analyzers, live + photo screens
    profile/     athlete details, appearance customiser
```

Clean Architecture per feature (`data` / `domain` / `presentation`), state via
`flutter_bloc`, dependencies via `get_it`.

The per-exercise analyzers live in `lib/features/workout/domain/analyzers/`.
Each extends `ExerciseAnalyzer`, which handles pose selection, left/right side
selection, confidence gating and angle smoothing, leaving each subclass to
define only its own thresholds and scoring.

## Running it

```sh
flutter pub get
flutter run
```

Needs a physical device — pose detection requires a real camera. Grant camera
access on first launch; photo access is only asked for when you pick an image.

```sh
flutter test      # analyzer logic + widget tests
flutter analyze
```

## Filming tips

Stand side-on, about two metres from the phone, with your shoulder, hip, knee
and ankle all in frame. The analyzers pick whichever side of your body is more
confidently visible and read the angles from that.
