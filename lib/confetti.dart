import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

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
        blastDirection: pi / 2,
        particleDrag: 0.05,
        emissionFrequency: 0.05,
        numberOfParticles: 50,
        gravity: 0.05,
        shouldLoop: false,
        colors: const [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ],
      ),
    );
  }
}
