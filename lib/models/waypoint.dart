import 'package:flutter/material.dart';

class Waypoint {
  final double dx;
  final double dy;

  const Waypoint(this.dx, this.dy);

  Offset toOffset() => Offset(dx, dy);

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};
}
