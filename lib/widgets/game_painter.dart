import 'dart:math';
import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../game/path_manager.dart';
import '../utils/constants.dart';

class GamePainter extends CustomPainter {
  final GameController controller;

  GamePainter({required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Scale canvas to translate logical coordinates (400x700) to actual canvas dimensions
    final double scale = size.width / GameConstants.logicalWidth;
    canvas.save();
    canvas.scale(scale);

    // 1. (Removed Cosmic Background to show the Theme Image underneath)

    // 2. Draw Spline Path (Neon Dotted Guide Track)
    _drawPathTrack(canvas);



    // 4. Draw Active Ball Chain (with wrong-tap shake displacements)
    _drawActiveBalls(canvas);

    // 5. Draw Flying Balls (with 3D pop bounce arcs and comet tails)
    _drawFlyingBalls(canvas);

    // 6. Draw Box (Concentric rotating segmented vortex & breathing portal)
    _drawBox(canvas);

    // 7. Draw Tap Effects (expanding ripples)
    _drawTapEffects(canvas);

    // 8. Draw Particle Effects (Sparks & Confetti)
    _drawParticles(canvas);

    canvas.restore();
  }

  void _drawCosmicBackground(Canvas canvas, Size size) {
    // Warm deep charcoal dark background
    final bgPaint = Paint()..color = GameConstants.obsidianBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Drifting subtle geometric polygon shapes
    final polygonPaint = Paint()
      ..color = const Color(0xFF1E1E2E).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      double t = controller.totalElapsedTime * 0.03 + (i * 15.0);
      double centerX = size.width * (0.3 + 0.4 * sin(t * 0.8));
      double centerY = size.height * (0.2 + 0.6 * (t % 1.0));
      double radius = 70.0 + i * 35.0;

      final path = Path();
      int sides = 3 + (i % 2); // Drift triangles and diamonds/squares
      for (int s = 0; s < sides; s++) {
        double angle = (s * 2 * pi / sides) + t * 0.15;
        double x = centerX + cos(angle) * radius;
        double y = centerY + sin(angle) * radius;
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, polygonPaint);
    }
  }

  void _drawPathTrack(Canvas canvas) {
    if (controller.pathPoints.isEmpty) return;

    final themeColor = GameConstants.getLevelColor(controller.currentLevelNumber - 1, theme: controller.currentTheme);

    // Calculate warning path color shift (when chain is near the box)
    double warningIntensity = 0.0;
    if (controller.activeBalls.isNotEmpty) {
      double headDist = controller.activeBalls.first.distance;
      double distToBox = controller.totalPathLength - headDist;
      if (distToBox < 160.0) {
        warningIntensity = (1.0 - (distToBox / 160.0)).clamp(0.0, 1.0);
      }
    }
    double pulse = 0.6 + 0.4 * sin(controller.totalElapsedTime * 7.0);
    double warningAlpha = warningIntensity * pulse;

    if (controller.cachedTrackPicture != null) {
      canvas.drawPicture(controller.cachedTrackPicture!);
    }

    if (warningAlpha > 0.0 && controller.trackPath != null) {
      final warningPaint = Paint()
        ..color = Color.lerp(Colors.transparent, GameConstants.neonRed.withOpacity(0.65), warningAlpha)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(controller.trackPath!, warningPaint);
    }

    // 4. Draw Animated Flowing Energy Dots along the center of the track
    Color centerLineColor = themeColor.withOpacity(0.45);
    if (warningAlpha > 0.0) {
      centerLineColor = Color.lerp(centerLineColor, GameConstants.neonRed.withOpacity(0.85), warningAlpha)!;
    }

    final dotPaint = Paint()
      ..color = centerLineColor
      ..style = PaintingStyle.fill;

    double dotSpacing = 24.0;
    double speed = 40.0; // Flow speed (pixels per second)
    double offset = (controller.totalElapsedTime * speed) % dotSpacing;

    for (double d = offset; d < controller.totalPathLength; d += dotSpacing) {
      final posAngle = PathManager.getPositionAtDistance(d, controller.pathPoints, controller.pathDistances);
      
      // Draw a glowing outer circle for each dot
      final dotGlow = Paint()
        ..color = centerLineColor.withOpacity(0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(posAngle.position, 4.0, dotGlow);

      // Draw solid inner core
      canvas.drawCircle(posAngle.position, 1.8, dotPaint);
    }
  }

  void _drawActiveBalls(Canvas canvas) {
    for (var ball in controller.activeBalls) {
      if (ball.visualScale > 0.0) {
        Offset pos = ball.currentPos;
        if (ball.shakeTimer > 0.0) {
          // Subtle fast wrong-color shake
          double disp = ball.shakeTimer * 6.0;
          pos += Offset(
            sin(ball.shakeTimer * 120.0) * disp,
            cos(ball.shakeTimer * 100.0) * disp,
          );
        }
        _draw3DBall(canvas, pos, ball.color, ball.visualScale);
      }
    }
  }

  void _drawFlyingBalls(Canvas canvas) {
    for (var flyBall in controller.flyingBalls) {
      final currentPos = flyBall.getPosition();
      double heightBounce = sin(flyBall.t * pi) * 0.35;
      double scale = 1.0 + heightBounce;

      // Draw subtle motion blur trail behind flying ball
      for (int i = 2; i >= 1; i--) {
        double ghostT = flyBall.t - (i * 0.035);
        if (ghostT > 0.0) {
          double mt = 1.0 - ghostT;
          final ghostPos = flyBall.startPosition * (mt * mt) +
              flyBall.controlPoint * (2 * mt * ghostT) +
              flyBall.endPosition * (ghostT * ghostT);
          
          double ghostBounce = sin(ghostT * pi) * 0.35;
          double ghostScale = (1.0 - (i * 0.15)) * (1.0 + ghostBounce);
          double ghostOpacity = 0.4 - (i * 0.12);
          _draw3DBall(
            canvas,
            ghostPos,
            flyBall.color,
            ghostScale,
            opacity: ghostOpacity.clamp(0.0, 1.0),
          );
        }
      }

      _draw3DBall(canvas, currentPos, flyBall.color, scale);
    }
  }

  void _drawBox(Canvas canvas) {
    final box = controller.box;
    if (box == null) return;

    // Egg-carton style container box holding slots horizontally
    double slotSpacing = 36.0 * box.bounceScale;
    double boxWidth = ((box.requiredCount - 1) * slotSpacing + 46.0);
    double boxHeight = 48.0 * box.bounceScale;
    final cardRect = Rect.fromCenter(center: box.position, width: boxWidth, height: boxHeight);
    final cardRRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(14.0));

    // 1. Draw subtle soft drop shadow behind the box card
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawRRect(cardRRect.shift(const Offset(0.0, 3.0)), shadowPaint);

    // 2. Draw card background (frosted / matte surface)
    final cardBgPaint = Paint()..color = const Color(0xFF1E1E2E).withOpacity(0.92);
    canvas.drawRRect(cardRRect, cardBgPaint);

    // Card border outline (thick and highly visible target color indicator)
    final cardBorderPaint = Paint()
      ..color = box.targetColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cardRRect, cardBorderPaint);

    // 3. Draw egg-box slots/cups inside the card
    double startX = box.position.dx - ((box.requiredCount - 1) * slotSpacing) / 2;
    for (int i = 0; i < box.requiredCount; i++) {
      Offset slotPos = Offset(startX + (i * slotSpacing), box.position.dy);
      bool isFilled = i < box.currentCount;

      if (isFilled) {
        // Draw the 3D-looking matte ball of the target color sitting inside the cup!
        _draw3DBall(canvas, slotPos, box.targetColor, 0.74 * box.bounceScale);
      } else {
        // Draw empty egg carton cup pocket (concave depth)
        final cupBgPaint = Paint()
          ..color = const Color(0xFF0F0F1A)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(slotPos, 12.0 * box.bounceScale, cupBgPaint);

        // Highlight ring of the cup pocket: colored to target color
        final cupRingPaint = Paint()
          ..color = box.targetColor.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(slotPos, 12.0 * box.bounceScale, cupRingPaint);

        // Small indicator dot inside the empty cup: bright solid target color
        final cupDotPaint = Paint()
          ..color = box.targetColor.withOpacity(0.85)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(slotPos, 4.5 * box.bounceScale, cupDotPaint);
      }
    }

    // 4. Clean white flash overlay on complete/land
    if (box.explosionOpacity > 0.0) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(box.explosionOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(cardRRect, flashPaint);
    }
  }

  void _drawTapEffects(Canvas canvas) {
    for (var effect in controller.tapEffects) {
      double opacity = (1.0 - effect.t).clamp(0.0, 1.0);
      if (effect.isCorrect) {
        // Correct tap: clean white ring ripple
        double radius = GameConstants.ballRadius + (effect.t * 26.0);
        final paint = Paint()
          ..color = Colors.white.withOpacity(opacity * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(effect.position, radius, paint);
      } else {
        // Wrong tap: subtle small ring ripple
        double radius = GameConstants.ballRadius + (effect.t * 12.0);
        final paint = Paint()
          ..color = effect.color.withOpacity(opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(effect.position, radius, paint);
      }
    }
  }

  void _drawParticles(Canvas canvas) {
    for (var p in controller.particles) {
      final paint = Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0));
      if (p.isConfetti) {
        canvas.save();
        canvas.translate(p.position.dx, p.position.dy);
        canvas.rotate(p.life * pi * 4);
        final rect = Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size);
        canvas.drawRect(rect, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(p.position, p.size, paint);
      }
    }
  }

  void _draw3DBall(Canvas canvas, Offset position, Color color, double scale, {double opacity = 1.0}) {
    final double radius = GameConstants.ballRadius * scale;
    if (radius <= 0) return;

    // 1. Soft matte drop shadow offset below the ball
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.24 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(position + const Offset(0.0, 2.5), radius, shadowPaint);

    // 2. Linear gradient for subtle 3D depth (matte surface, no glossy specs)
    final hsl = HSLColor.fromColor(color);
    final lightColor = hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
    final darkColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          lightColor.withOpacity(opacity),
          color.withOpacity(opacity),
          darkColor.withOpacity(opacity),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: radius));

    canvas.drawCircle(position, radius, paint);

    // Subtle dark border ring
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.08 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(position, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
