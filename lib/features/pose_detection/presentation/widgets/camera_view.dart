import 'package:flutter/material.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key, required this.overlay});

  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(
                child: Text(
                  'Camera Preview',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              overlay,
            ],
          ),
        ),
      ),
    );
  }
}
