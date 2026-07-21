import 'package:flutter/material.dart';
import '../models/waypoint.dart';

class PositionAngle {
  final Offset position;
  final double angle;

  PositionAngle(this.position, this.angle);
}

class PathManager {
  // Generates a smooth list of points along the path using Catmull-Rom interpolation
  static List<Offset> generateSmoothPath(
    List<Waypoint> waypoints, {
    int pointsPerSegment = 30,
  }) {
    if (waypoints.isEmpty) return [];
    if (waypoints.length < 2)
      return waypoints.map((w) => w.toOffset()).toList();

    List<Offset> controlPoints = waypoints.map((w) => w.toOffset()).toList();
    List<Offset> path = [];

    // Duplicate start and end points for Catmull-Rom boundary conditions
    List<Offset> pts = [
      controlPoints.first,
      ...controlPoints,
      controlPoints.last,
    ];

    for (int i = 1; i < pts.length - 2; i++) {
      Offset p0 = pts[i - 1];
      Offset p1 = pts[i];
      Offset p2 = pts[i + 1];
      Offset p3 = pts[i + 2];

      for (int j = 0; j < pointsPerSegment; j++) {
        double t = j / pointsPerSegment;
        double t2 = t * t;
        double t3 = t2 * t;

        double x =
            0.5 *
            ((2 * p1.dx) +
                (-p0.dx + p2.dx) * t +
                (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
                (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

        double y =
            0.5 *
            ((2 * p1.dy) +
                (-p0.dy + p2.dy) * t +
                (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
                (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

        path.add(Offset(x, y));
      }
    }
    path.add(controlPoints.last);
    return path;
  }

  // Precalculates cumulative distances for each point along the generated path
  static List<double> computeCumulativeDistances(List<Offset> path) {
    if (path.isEmpty) return [0.0];
    List<double> distances = [0.0];
    double total = 0.0;
    for (int i = 1; i < path.length; i++) {
      total += (path[i] - path[i - 1]).distance;
      distances.add(total);
    }
    return distances;
  }

  // Finds the Offset and Angle at a specific travel distance along the path using binary search
  static PositionAngle getPositionAtDistance(
    double distance,
    List<Offset> path,
    List<double> cumulativeDistances,
  ) {
    if (path.isEmpty) return PositionAngle(Offset.zero, 0.0);
    double totalLength = cumulativeDistances.last;

    // Clamp or extrapolate distance
    if (distance <= 0) {
      Offset dir = path.length > 1 ? (path[1] - path[0]) : Offset.zero;
      double len = dir.distance;
      if (len > 0.0) {
        Offset normDir = dir / len;
        // Since distance is negative or zero, this offsets backwards along the entry tangent
        return PositionAngle(path.first + normDir * distance, dir.direction);
      }
      return PositionAngle(path.first, dir.direction);
    }
    if (distance >= totalLength) {
      Offset dir = path.length > 1
          ? (path.last - path[path.length - 2])
          : Offset.zero;
      return PositionAngle(path.last, dir.direction);
    }

    // Binary search to find which segment contains the target distance
    int low = 0;
    int high = cumulativeDistances.length - 1;
    while (low < high - 1) {
      int mid = (low + high) ~/ 2;
      if (cumulativeDistances[mid] < distance) {
        low = mid;
      } else {
        high = mid;
      }
    }

    double d0 = cumulativeDistances[low];
    double d1 = cumulativeDistances[high];
    double t = (distance - d0) / (d1 - d0);

    Offset p0 = path[low];
    Offset p1 = path[high];
    Offset pos = Offset.lerp(p0, p1, t)!;
    Offset dir = p1 - p0;

    return PositionAngle(pos, dir.direction);
  }
}
