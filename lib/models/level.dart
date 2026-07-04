import 'package:flutter/material.dart';
import 'waypoint.dart';

class LevelConfig {
  final int levelNumber;
  final String name;
  final List<Waypoint> controlPoints;
  final Offset boxPosition;
  final double speedMultiplier;
  final int boxDemand; // How many balls of target color the box needs
  final int colorCount; // Number of active colors in this level

  const LevelConfig({
    required this.levelNumber,
    required this.name,
    required this.controlPoints,
    required this.boxPosition,
    required this.speedMultiplier,
    required this.boxDemand,
    required this.colorCount,
  });

  // Scaling getters to safely map coordinates inside [60, 340] for X and [140, 600] for Y
  List<Waypoint> get scaledControlPoints {
    return controlPoints.map((w) {
      // Map x from original range [40, 360] to [60, 340]
      double newX = 60.0 + (w.dx - 40.0) * (340.0 - 60.0) / (360.0 - 40.0);
      newX = newX.clamp(60.0, 340.0);

      // Map y from original range [80, 660] to [140, 600]
      double newY = 140.0 + (w.dy - 80.0) * (600.0 - 140.0) / (660.0 - 80.0);
      newY = newY.clamp(140.0, 600.0);

      return Waypoint(newX, newY);
    }).toList();
  }

  Offset get scaledBoxPosition {
    // Map x from original range [40, 360] to [60, 340]
    double newX = 60.0 + (boxPosition.dx - 40.0) * (340.0 - 60.0) / (360.0 - 40.0);
    newX = newX.clamp(60.0, 340.0);

    // Map y from original range [80, 660] to [140, 600]
    double newY = 140.0 + (boxPosition.dy - 80.0) * (600.0 - 140.0) / (660.0 - 80.0);
    newY = newY.clamp(140.0, 600.0);

    return Offset(newX, newY);
  }

  // Pre-configured levels with gorgeous spiral trajectories
  static List<LevelConfig> get defaultLevels => [
    LevelConfig(
      levelNumber: 1,
      name: "Oddiy Spiral (Simple Spiral)",
      controlPoints: const [
        Waypoint(40, 100),
        Waypoint(350, 100),
        Waypoint(350, 580),
        Waypoint(60, 580),
        Waypoint(60, 200),
        Waypoint(300, 200),
        Waypoint(300, 480),
        Waypoint(110, 480),
        Waypoint(110, 290),
        Waypoint(250, 290),
        Waypoint(250, 390),
        Waypoint(180, 390), // Path ends at box in center
      ],
      boxPosition: const Offset(180, 390),
      speedMultiplier: 1.0,
      boxDemand: 3,
      colorCount: 3,
    ),
    LevelConfig(
      levelNumber: 2,
      name: "Katta Spiral (Large Spiral)",
      controlPoints: const [
        Waypoint(200, 90),
        Waypoint(360, 150),
        Waypoint(360, 580),
        Waypoint(40, 580),
        Waypoint(40, 150),
        Waypoint(300, 210),
        Waypoint(300, 510),
        Waypoint(100, 510),
        Waypoint(100, 270),
        Waypoint(250, 270),
        Waypoint(250, 430),
        Waypoint(170, 430),
        Waypoint(170, 350), // Path ends at box
      ],
      boxPosition: const Offset(170, 350),
      speedMultiplier: 1.3,
      boxDemand: 3,
      colorCount: 4,
    ),
    LevelConfig(
      levelNumber: 3,
      name: "Burchakli Spiral (Hex Spiral)",
      controlPoints: const [
        Waypoint(200, 80),
        Waypoint(360, 180),
        Waypoint(360, 540),
        Waypoint(200, 640),
        Waypoint(40, 540),
        Waypoint(40, 180),
        Waypoint(200, 170),
        Waypoint(300, 230),
        Waypoint(300, 480),
        Waypoint(200, 550),
        Waypoint(100, 480),
        Waypoint(100, 230),
        Waypoint(200, 260),
        Waypoint(240, 300),
        Waypoint(240, 420),
        Waypoint(200, 450),
        Waypoint(160, 420),
        Waypoint(160, 340),
        Waypoint(200, 360), // Center
      ],
      boxPosition: const Offset(200, 360),
      speedMultiplier: 1.6,
      boxDemand: 4,
      colorCount: 4,
    ),
    LevelConfig(
      levelNumber: 4,
      name: "Tugunli Spiral (Loop Spiral)",
      controlPoints: const [
        Waypoint(50, 90),
        Waypoint(350, 90),
        Waypoint(350, 640),
        Waypoint(50, 640),
        Waypoint(50, 200),
        Waypoint(300, 200),
        Waypoint(300, 530),
        Waypoint(100, 530),
        Waypoint(100, 290),
        Waypoint(250, 290),
        Waypoint(250, 430),
        Waypoint(160, 430),
        Waypoint(160, 360),
        Waypoint(200, 360), // Center
      ],
      boxPosition: const Offset(200, 360),
      speedMultiplier: 2.0,
      boxDemand: 4,
      colorCount: 5,
    ),
    LevelConfig(
      levelNumber: 5,
      name: "Cheksiz Burilish (Vortex Spiral)",
      controlPoints: const [
        Waypoint(40, 80),
        Waypoint(360, 80),
        Waypoint(360, 660),
        Waypoint(40, 660),
        Waypoint(40, 160),
        Waypoint(320, 160),
        Waypoint(320, 580),
        Waypoint(80, 580),
        Waypoint(80, 240),
        Waypoint(280, 240),
        Waypoint(280, 500),
        Waypoint(120, 500),
        Waypoint(120, 320),
        Waypoint(240, 320),
        Waypoint(240, 420),
        Waypoint(170, 420),
        Waypoint(170, 370), // Center
      ],
      boxPosition: const Offset(170, 370),
      speedMultiplier: 2.5,
      boxDemand: 5,
      colorCount: 5,
    ),
  ];
}
