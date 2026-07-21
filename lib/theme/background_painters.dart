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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0F111A),
    );

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
    final lightPaint = Paint()
      ..color = const Color(0x33E9C46A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      10,
      lightPaint,
    );
  }

  void _drawCityscape(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
    int buildingCount,
  ) {
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF14171A),
    );

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

  void _drawHills(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
    int hillCount,
  ) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    double step = size.width / hillCount;
    for (int i = 0; i <= hillCount; i++) {
      double cx = offsetX + step * i;
      path.quadraticBezierTo(
        cx - step / 2,
        size.height - size.height * heightRatio,
        cx,
        size.height,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPines(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
  ) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    double step = 40.0;
    Random rnd = Random(12);
    for (double x = offsetX; x < offsetX + size.width + step; x += step) {
      double th = size.height * heightRatio * (0.3 + rnd.nextDouble() * 0.3);
      path.lineTo(x, size.height);
      path.lineTo(x + step / 2, size.height - th);
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1C1814),
    );

    // Sun/Moon
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.25),
      40,
      Paint()..color = const Color(0xFFD2B48C).withValues(alpha: 0.15),
    );

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

  void _drawPyramids(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
  ) {
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

  void _drawDunes(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
  ) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    path.quadraticBezierTo(
      offsetX + 150,
      size.height - size.height * heightRatio,
      offsetX + 300,
      size.height,
    );
    path.quadraticBezierTo(
      offsetX + 450,
      size.height - size.height * heightRatio * 0.8,
      offsetX + 600,
      size.height,
    );
    path.lineTo(offsetX + size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
}

class ElephantPainter extends ParallaxBackgroundPainter {
  ElephantPainter(super.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    // Spooky foggy background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF161A18),
    );

    // Layer 1: Distant tusks and bones
    final p1 = Paint()..color = const Color(0xFF202A24);
    double offset1 = (animationVal * 15) % size.width;
    _drawTusks(canvas, size, p1, offset1, 0.35);
    _drawTusks(canvas, size, p1, offset1 - size.width, 0.35);

    // Layer 2: Midground spooky rocky terrain
    final p2 = Paint()..color = const Color(0xFF2A362D);
    double offset2 = (animationVal * 30) % size.width;
    _drawRockyGround(canvas, size, p2, offset2, 0.3);
    _drawRockyGround(canvas, size, p2, offset2 - size.width, 0.3);

    // Layer 3: Foreground dark canopy (hanging moss/leaves) at the top
    final p3 = Paint()..color = const Color(0xFF101411);
    double offset3 = (animationVal * 45) % size.width;
    _drawCanopy(canvas, size, p3, offset3, 0.15);
    _drawCanopy(canvas, size, p3, offset3 - size.width, 0.15);

    // Foreground base ground
    final p4 = Paint()..color = const Color(0xFF1C241E);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
      p4,
    );
  }

  void _drawTusks(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
  ) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    double step = 120.0;
    Random rnd = Random(42);
    for (double x = offsetX; x <= offsetX + size.width + step; x += step) {
      if (rnd.nextBool()) {
        double th = size.height * heightRatio * (0.6 + rnd.nextDouble() * 0.4);
        // Draw a curved tusk sticking out of the ground
        path.moveTo(x, size.height);
        path.quadraticBezierTo(
          x - 40,
          size.height - th / 2,
          x + 20,
          size.height - th,
        );
        path.quadraticBezierTo(
          x - 10,
          size.height - th / 2,
          x + 30,
          size.height,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawRockyGround(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
  ) {
    final path = Path();
    path.moveTo(offsetX, size.height);
    double step = 80.0;
    Random rnd = Random(88);
    for (double x = offsetX; x <= offsetX + size.width + step; x += step) {
      double gh = size.height * heightRatio * (0.4 + rnd.nextDouble() * 0.6);
      path.lineTo(x - step / 2, size.height - gh);
      path.lineTo(x, size.height - gh * 0.8);
    }
    path.lineTo(offsetX + size.width + step, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCanopy(
    Canvas canvas,
    Size size,
    Paint paint,
    double offsetX,
    double heightRatio,
  ) {
    final path = Path();
    path.moveTo(offsetX, 0);
    double step = 90.0;
    Random rnd = Random(123);
    for (
      double x = offsetX + step;
      x <= offsetX + size.width + step * 2;
      x += step
    ) {
      double prevX = x - step;
      double ch = size.height * heightRatio * (0.5 + rnd.nextDouble() * 0.5);
      // Smooth hanging moss/leaves
      path.cubicTo(prevX + step * 0.1, ch, x - step * 0.1, ch, x, 0);
    }
    path.lineTo(offsetX + size.width + step * 2, -50);
    path.lineTo(offsetX, -50);
    path.close();
    canvas.drawPath(path, paint);
  }
}
