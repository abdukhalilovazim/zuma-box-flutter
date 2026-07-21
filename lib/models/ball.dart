import 'package:flutter/material.dart';

class Ball {
  final String id;
  final Color color;

  // Distances along the spline path
  double distance;
  double targetDistance;

  // Visual/Animation properties
  double visualScale; // Used for scale-up / spawn intro
  Offset currentPos = Offset.zero; // For caching position
  double currentAngle = 0.0; // For caching tangent angle
  double shakeTimer = 0.0; // For wrong-tap shake animation

  Ball({
    required this.id,
    required this.color,
    required this.distance,
    required this.targetDistance,
    this.visualScale = 1.0,
    this.shakeTimer = 0.0,
  });

  // Create a copy with optional modifications
  Ball copyWith({
    String? id,
    Color? color,
    double? distance,
    double? targetDistance,
    double? visualScale,
    double? shakeTimer,
  }) {
    return Ball(
      id: id ?? this.id,
      color: color ?? this.color,
      distance: distance ?? this.distance,
      targetDistance: targetDistance ?? this.targetDistance,
      visualScale: visualScale ?? this.visualScale,
      shakeTimer: shakeTimer ?? this.shakeTimer,
    );
  }
}

class FlyingBall {
  final String id;
  final Color color;
  final Offset startPosition;
  final Offset endPosition;
  final Offset controlPoint;
  double t; // Ranges from 0.0 (start) to 1.0 (end)

  FlyingBall({
    required this.id,
    required this.color,
    required this.startPosition,
    required this.endPosition,
    required this.controlPoint,
    this.t = 0.0,
  });

  // Calculate quadratic Bezier position
  Offset getPosition() {
    double mt = 1.0 - t;
    return startPosition * (mt * mt) +
        controlPoint * (2 * mt * t) +
        endPosition * (t * t);
  }
}
