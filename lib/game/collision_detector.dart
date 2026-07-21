import 'package:flutter/material.dart';
import '../models/ball.dart';

class CollisionDetector {
  /// Checks if a logical tap position hits any ball in the active chain.
  /// Returns the index of the tapped ball, or null if no ball was tapped.
  static int? detectTappedBall({
    required Offset logicalTapPos,
    required List<Ball> activeBalls,
    required double ballRadius,
    double tolerance = 12.0, // Extra tapping area padding for better mobile UX
  }) {
    for (int i = 0; i < activeBalls.length; i++) {
      final ball = activeBalls[i];
      // Only normal scale balls can be tapped
      if (ball.visualScale < 0.8) continue;

      final distance = (logicalTapPos - ball.currentPos).distance;
      if (distance <= (ballRadius + tolerance)) {
        return i; // Return the first hit index
      }
    }
    return null;
  }
}
