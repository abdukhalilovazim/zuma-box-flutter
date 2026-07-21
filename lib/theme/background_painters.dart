import 'dart:math';
import 'package:flutter/material.dart';

abstract class ParallaxBackgroundPainter extends CustomPainter {
  final double animationVal;
  ParallaxBackgroundPainter(this.animationVal);

  @override
  bool shouldRepaint(covariant ParallaxBackgroundPainter oldDelegate) {
    return oldDelegate.animationVal != animationVal;
  }
}

class TokyoPainter extends ParallaxBackgroundPainter {
  TokyoPainter(super.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep midnight blue/charcoal background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0F111A));

    // Layer 1: Distant City (Slow)
    final p1 = Paint()..color = const Color(0xFF1A1D2E);
    double offset1 = (animationVal * 20) % size.width;
    _drawCityscape(canvas, size, p1, offset1, 0.4, 8);
    _drawCityscape(canvas, size, p1, offset1 - size.width, 0.4, 8);

    // Layer 2: Midground City (Medium)
    final p2 = Paint()..color = const Color(0xFF24283D);
    double offset2 = (animationVal * 40) % size.width;
    _drawCityscape(canvas, size, p2, offset2, 0.6, 12);
    _drawCityscape(canvas, size, p2, offset2 - size.width, 0.6, 12);

    // Subtle lights
    final lightPaint = Paint()..color = const Color(0x33E9C46A)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 10, lightPaint);
  }

  void _drawCityscape(Canvas canvas, Size size, Paint paint, double offsetX, double heightRatio, int buildingCount) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    
    double step = size.width / buildingCount;
    Random rnd = Random(42); // Fixed seed for stable buildings

    double currentX = offsetX;
    for (int i = 0; i <= buildingCount; i++) {
      double bh = size.height * heightRatio * (0.5 + rnd.nextDouble() * 0.5);
      path.lineTo(currentX, size.height - bh);
      path.lineTo(currentX + step * 0.8, size.height - bh);
      path.lineTo(currentX + step * 0.8, size.height);
      currentX += step;
    }
    path.lineTo(offsetX + size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
}

class GermanyPainter extends ParallaxBackgroundPainter {
  GermanyPainter(super.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF14171A));

    // Distant foggy hills
    final p1 = Paint()..color = const Color(0xFF1F2429);
    double offset1 = (animationVal * 15) % size.width;
    _drawHills(canvas, size, p1, offset1, 0.5, 3);
    _drawHills(canvas, size, p1, offset1 - size.width, 0.5, 3);

    // Castle / Trees
    final p2 = Paint()..color = const Color(0xFF2B3238);
    double offset2 = (animationVal * 30) % size.width;
    _drawPines(canvas, size, p2, offset2, 0.7);
    _drawPines(canvas, size, p2, offset2 - size.width, 0.7);
  }

  void _drawHills(Canvas canvas, Size size, Paint paint, double offsetX, double heightRatio, int hillCount) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    double step = size.width / hillCount;
    for (int i = 0; i <= hillCount; i++) {
      double cx = offsetX + step * i;
      path.quadraticBezierTo(cx - step/2, size.height - size.height * heightRatio, cx, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPines(Canvas canvas, Size size, Paint paint, double offsetX, double heightRatio) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    double step = 40.0;
    Random rnd = Random(12);
    for (double x = offsetX; x < offsetX + size.width + step; x += step) {
      double th = size.height * heightRatio * (0.3 + rnd.nextDouble() * 0.3);
      path.lineTo(x, size.height);
      path.lineTo(x + step/2, size.height - th);
      path.lineTo(x + step, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

class EgyptPainter extends ParallaxBackgroundPainter {
  EgyptPainter(super.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF1C1814));

    // Sun/Moon
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.25), 40, Paint()..color = const Color(0xFFD2B48C).withValues(alpha: 0.15));

    // Distant Pyramids
    final p1 = Paint()..color = const Color(0xFF2B221B);
    double offset1 = (animationVal * 10) % size.width;
    _drawPyramids(canvas, size, p1, offset1, 0.4);
    _drawPyramids(canvas, size, p1, offset1 - size.width, 0.4);

    // Sand Dunes
    final p2 = Paint()..color = const Color(0xFF382C24);
    double offset2 = (animationVal * 25) % size.width;
    _drawDunes(canvas, size, p2, offset2, 0.6);
    _drawDunes(canvas, size, p2, offset2 - size.width, 0.6);
  }

  void _drawPyramids(Canvas canvas, Size size, Paint paint, double offsetX, double heightRatio) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    path.lineTo(offsetX + 100, size.height - size.height * heightRatio);
    path.lineTo(offsetX + 200, size.height);
    path.lineTo(offsetX + 300, size.height - size.height * heightRatio * 0.7);
    path.lineTo(offsetX + 400, size.height);
    path.lineTo(offsetX + size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDunes(Canvas canvas, Size size, Paint paint, double offsetX, double heightRatio) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    path.quadraticBezierTo(offsetX + 150, size.height - size.height * heightRatio, offsetX + 300, size.height);
    path.quadraticBezierTo(offsetX + 450, size.height - size.height * heightRatio * 0.8, offsetX + 600, size.height);
    path.lineTo(offsetX + size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
}

class ElephantPainter extends ParallaxBackgroundPainter {
  ElephantPainter(super.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF121A15));

    // Distant canopy
    final p1 = Paint()..color = const Color(0xFF19241C);
    double offset1 = (animationVal * 15) % size.width;
    _drawCanopy(canvas, size, p1, offset1, 0.2);
    _drawCanopy(canvas, size, p1, offset1 - size.width, 0.2);

    // Midground flora
    final p2 = Paint()..color = const Color(0xFF223026);
    double offset2 = (animationVal * 35) % size.width;
    _drawCanopy(canvas, size, p2, offset2, 0.4);
    _drawCanopy(canvas, size, p2, offset2 - size.width, 0.4);
    
    // Foreground base
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2), Paint()..color = const Color(0xFF2B3A2F));
  }

  void _drawCanopy(Canvas canvas, Size size, Paint paint, double offsetX, double heightRatio) {
    final path = Path();
    path.moveTo(offsetX, 0);
    double step = 60.0;
    Random rnd = Random(88);
    for (double x = offsetX; x <= offsetX + size.width + step; x += step) {
      double ch = size.height * heightRatio * (0.5 + rnd.nextDouble() * 0.5);
      path.quadraticBezierTo(x - step/2, ch, x, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
