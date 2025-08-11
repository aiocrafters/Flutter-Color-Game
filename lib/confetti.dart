import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// A custom confetti widget for the app.
class AppConfetti extends StatelessWidget {
  final ConfettiController controller;
  final Alignment alignment;

  const AppConfetti({
    super.key,
    required this.controller,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality
            .explosive, // Enhanced: Explosive burst for all directions, more exciting than single downward[1][5]
        shouldLoop: false, // Plays once per success, as before
        numberOfParticles:
            100, // Increased from 50 for a denser, more festive shower[4][6]
        minBlastForce: 10, // New: Minimum force for varied particle speeds[4]
        maxBlastForce: 30, // New: Maximum force for dynamic spread[4]
        emissionFrequency:
            0.02, // Slightly higher frequency for quicker bursts[1][2]
        gravity:
            0.2, // Reduced gravity for slower, floating fall – feels more magical[1][5]
        particleDrag:
            0.05, // New: Adds slight resistance for realistic motion[6]
        colors: const [
          // Expanded: More vibrant, kid-friendly colors with variety[1][4]
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
          Colors.cyan,
          Colors.lime,
        ],
        createParticlePath:
            drawStar, // New: Custom star shape mixed in for fun (see helper below)[10]
      ),
    );
  }

  // New: Helper to draw a star shape for some particles – adds whimsy[5][10]
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth * 0.5; // Adjust for pointiness
    final path = Path();
    final degreesPerStep = 360 / numberOfPoints;
    final halfDegreesPerStep = degreesPerStep / 2;
    final pathCenter = Offset(size.width / 2, size.height / 2);

    path.moveTo(size.width / 2, 0); // Start at top
    for (double step = 0; step < numberOfPoints; step++) {
      final double xExternal =
          pathCenter.dx +
          cos(degToRad(step * degreesPerStep + halfDegreesPerStep)) *
              externalRadius;
      final double yExternal =
          pathCenter.dy +
          sin(degToRad(step * degreesPerStep + halfDegreesPerStep)) *
              externalRadius;
      path.lineTo(xExternal, yExternal);

      final double xInternal =
          pathCenter.dx +
          cos(degToRad((step + 1) * degreesPerStep)) * internalRadius;
      final double yInternal =
          pathCenter.dy +
          sin(degToRad((step + 1) * degreesPerStep)) * internalRadius;
      path.lineTo(xInternal, yInternal);
    }
    path.close();
    return path;
  }
}
