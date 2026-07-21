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
    double newX =
        60.0 + (boxPosition.dx - 40.0) * (340.0 - 60.0) / (360.0 - 40.0);
    newX = newX.clamp(60.0, 340.0);

    // Map y from original range [80, 660] to [140, 600]
    double newY =
        140.0 + (boxPosition.dy - 80.0) * (600.0 - 140.0) / (660.0 - 80.0);
    newY = newY.clamp(140.0, 600.0);

    return Offset(newX, newY);
  }

  // Pre-configured levels with gorgeous spiral trajectories
  static List<LevelConfig> get defaultLevels {
    final baseLayouts = [
      _BaseLayout(
        name: "Classic Spiral",
        points: const [
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
          Waypoint(170, 370),
        ],
        boxPos: const Offset(170, 370),
      ),
      _BaseLayout(
        name: "Jungle Snake",
        points: const [
          Waypoint(40, 80),
          Waypoint(360, 120),
          Waypoint(40, 200),
          Waypoint(360, 260),
          Waypoint(40, 340),
          Waypoint(360, 400),
          Waypoint(40, 480),
          Waypoint(360, 560),
          Waypoint(200, 640),
        ],
        boxPos: const Offset(200, 640),
      ),
      _BaseLayout(
        name: "Infinity Loop",
        points: const [
          Waypoint(40, 150),
          Waypoint(200, 350),
          Waypoint(360, 550),
          Waypoint(280, 650),
          Waypoint(120, 650),
          Waypoint(40, 550),
          Waypoint(200, 350),
          Waypoint(360, 150),
          Waypoint(280, 50),
          Waypoint(120, 50),
          Waypoint(40, 150),
          Waypoint(100, 250),
        ],
        boxPos: const Offset(100, 250),
      ),
      _BaseLayout(
        name: "Horseshoe",
        points: const [
          Waypoint(40, 600),
          Waypoint(40, 150),
          Waypoint(200, 80),
          Waypoint(360, 150),
          Waypoint(360, 600),
          Waypoint(280, 600),
          Waypoint(280, 220),
          Waypoint(200, 160),
          Waypoint(120, 220),
          Waypoint(120, 500),
          Waypoint(200, 500),
        ],
        boxPos: const Offset(200, 500),
      ),
      _BaseLayout(
        name: "Wavy River",
        points: const [
          Waypoint(200, 80),
          Waypoint(300, 150),
          Waypoint(100, 250),
          Waypoint(300, 350),
          Waypoint(100, 450),
          Waypoint(300, 550),
          Waypoint(200, 650),
        ],
        boxPos: const Offset(200, 650),
      ),
    ];

    final List<LevelConfig> configs = [];
    for (int i = 1; i <= 30; i++) {
      final base = baseLayouts[(i - 1) % 5];
      final bool mirrorX = (i % 2 == 0);
      final bool mirrorY = (i % 3 == 0);

      final mirroredPoints = base.points.map((w) {
        double px = w.dx;
        double py = w.dy;
        if (mirrorX) px = 400.0 - px;
        if (mirrorY) py = 740.0 - py;
        return Waypoint(px, py);
      }).toList();

      double bx = base.boxPos.dx;
      double by = base.boxPos.dy;
      if (mirrorX) bx = 400.0 - bx;
      if (mirrorY) by = 740.0 - by;

      final double speed = 0.75 + (i - 1) * 0.08;
      final int demand = 2 + ((i - 1) ~/ 7);
      final int colors = 3 + ((i - 1) ~/ 10);

      configs.add(
        LevelConfig(
          levelNumber: i,
          name: "${base.name} - $i",
          controlPoints: mirroredPoints,
          boxPosition: Offset(bx, by),
          speedMultiplier: speed,
          boxDemand: demand.clamp(2, 6),
          colorCount: colors.clamp(3, 5),
        ),
      );
    }
    return configs;
  }
}

class _BaseLayout {
  final String name;
  final List<Waypoint> points;
  final Offset boxPos;
  const _BaseLayout({
    required this.name,
    required this.points,
    required this.boxPos,
  });
}
