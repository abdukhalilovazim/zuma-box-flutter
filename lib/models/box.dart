import 'package:flutter/material.dart';

class BoxModel {
  Color targetColor;
  int currentCount;
  final int requiredCount;
  final Offset position;

  // Visual/Animation States
  double bounceScale = 1.0;
  double explosionScale = 0.0;
  double explosionOpacity = 0.0;

  BoxModel({
    required this.targetColor,
    required this.requiredCount,
    required this.position,
    this.currentCount = 0,
  });

  void reset(Color newColor) {
    targetColor = newColor;
    currentCount = 0;
    bounceScale = 1.0;
    explosionScale = 0.0;
    explosionOpacity = 0.0;
  }

  bool addBall() {
    currentCount++;
    bounceScale = 1.25; // Trigger a small bounce effect
    if (currentCount >= requiredCount) {
      explosionScale = 1.0;
      explosionOpacity = 1.0;
      return true; // Target met!
    }
    return false;
  }
}
