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

    // 1. Theme Background is handled by DynamicBackground in the GameScreen

    // 2. Draw Spline Path (Flat Muted Guide Track)
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

  void _drawPathTrack(Canvas canvas) {
    if (controller.pathPoints.isEmpty) return;

    final themeColor = GameConstants.getLevelColor(
      controller.currentLevelNumber - 1,
      theme: controller.currentTheme,
    );

    // Draw Spawn Cave/Hole at the start of the path
    final startPos = controller.pathPoints.first;
    final spawnShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(startPos, 24.0, spawnShadow);

    final spawnHole = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPos, 18.0, spawnHole);

    final spawnBorder = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(startPos, 18.0, spawnBorder);

    // Draw Magical Portal at the end of the path (Danger Hole)
    final endPos = controller.pathPoints.last;
    final double endBaseRadius = 28.0;

    // Calculate warning path color shift (when chain is near the box)
    double warningIntensity = 0.0;
    if (controller.activeBalls.isNotEmpty) {
      double headDist = controller.activeBalls.first.distance;
      double distToBox = controller.totalPathLength - headDist;
      if (distToBox < 300.0 && distToBox > 0.0) {
        warningIntensity = (1.0 - (distToBox / 300.0)).clamp(0.0, 1.0);
      }
    }
    double pulse = 0.6 + 0.4 * sin(controller.totalElapsedTime * 7.0);
    double warningAlpha = warningIntensity * pulse;

    final auraPaint = Paint()
      ..color = GameConstants.neonRed.withValues(alpha: warningIntensity * 0.5 + 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
    canvas.drawCircle(endPos, endBaseRadius * 1.5, auraPaint);

    final portalPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF05050A),
          const Color(0xFF250505),
        ],
      ).createShader(Rect.fromCircle(center: endPos, radius: endBaseRadius));
    canvas.drawCircle(endPos, endBaseRadius, portalPaint);

    final ringPaint = Paint()
      ..color = GameConstants.neonRed.withValues(alpha: 0.6 + (warningAlpha * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(endPos, endBaseRadius, ringPaint);

    // Rotating inner runic dashes
    canvas.save();
    canvas.translate(endPos.dx, endPos.dy);
    canvas.rotate(controller.totalElapsedTime * 2.0);
    final dashPaint = Paint()
      ..color = GameConstants.neonRed.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    for (int i = 0; i < 6; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: endBaseRadius - 5),
        i * (pi / 3),
        pi / 6,
        false,
        dashPaint,
      );
    }
    canvas.restore();

    // (Warning intensity is calculated above now)
      canvas.drawPicture(controller.cachedTrackPicture!);
    }

    if (warningAlpha > 0.0 && controller.trackPath != null) {
      final warningPaint = Paint()
        ..color = Color.lerp(
          Colors.transparent,
          const Color(0x33FF0000),
          warningAlpha,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(controller.trackPath!, warningPaint);
    }

    // 4. Draw Animated Flowing Energy Dots along the center of the track
    Color centerLineColor = themeColor.withValues(alpha: 0.45);
    if (warningAlpha > 0.0) {
      centerLineColor = Color.lerp(
        centerLineColor,
        GameConstants.neonRed.withValues(alpha: 0.85),
        warningAlpha,
      )!;
    }

    final dotPaint = Paint()
      ..color = centerLineColor
      ..style = PaintingStyle.fill;

    double dotSpacing = 24.0;
    double speed = 40.0; // Flow speed (pixels per second)
    double offset = (controller.totalElapsedTime * speed) % dotSpacing;

    for (double d = offset; d < controller.totalPathLength; d += dotSpacing) {
      final posAngle = PathManager.getPositionAtDistance(
        d,
        controller.pathPoints,
        controller.pathDistances,
      );

      // Draw solid inner core
      canvas.drawCircle(posAngle.position, 2.5, dotPaint);
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

        // Add Warning Glow for balls near the box
        double distToBox = controller.totalPathLength - ball.distance;
        if (distToBox < 300.0 && distToBox > 0.0) {
          double warningIntensity = (1.0 - (distToBox / 300.0)).clamp(0.0, 1.0);
          double pulse = 0.5 + 0.5 * sin(controller.totalElapsedTime * 10.0);
          double glowAlpha = warningIntensity * pulse * 0.8;

          if (glowAlpha > 0.0) {
            // Soft red glow behind the ball
            final glowPaint = Paint()
              ..color = GameConstants.neonRed.withValues(alpha: glowAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
            canvas.drawCircle(
              pos,
              GameConstants.ballRadius * ball.visualScale * 1.6,
              glowPaint,
            );

            // Sharp red ring around the ball
            final ringPaint = Paint()
              ..color = GameConstants.neonRed.withValues(alpha: glowAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5;
            canvas.drawCircle(
              pos,
              GameConstants.ballRadius * ball.visualScale * 1.15,
              ringPaint,
            );
          }
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
          final ghostPos =
              flyBall.startPosition * (mt * mt) +
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

    final center = box.position;

    // Draw a sleek Glass HUD style container
    final rect = Rect.fromCenter(center: center, width: 80, height: 44);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    // Glass Background
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, glassPaint);

    // Glass Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Draw Target Gem
    final gemPos = center - const Offset(20, 0);
    _draw3DBall(canvas, gemPos, box.targetColor, 0.65 * box.bounceScale);

    // Draw Text "1/3"
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${box.currentCount} / ${box.requiredCount}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16 * box.bounceScale,
          fontWeight: FontWeight.w600,
          fontFamily: 'CupertinoSystemDisplay',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center + Offset(5, -textPainter.height / 2),
    );

    // Flash overlay
    if (box.explosionOpacity > 0.0) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: box.explosionOpacity.clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, flashPaint);
    }
  }

  void _drawTapEffects(Canvas canvas) {
    for (var effect in controller.tapEffects) {
      double opacity = (1.0 - effect.t).clamp(0.0, 1.0);
      if (effect.isCorrect) {
        // Correct tap: clean white ring ripple
        double radius = GameConstants.ballRadius + (effect.t * 26.0);
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(effect.position, radius, paint);
      } else {
        // Wrong tap: subtle small ring ripple
        double radius = GameConstants.ballRadius + (effect.t * 12.0);
        final paint = Paint()
          ..color = effect.color.withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(effect.position, radius, paint);
      }
    }
  }

  void _drawParticles(Canvas canvas) {
    for (var p in controller.particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      if (p.isConfetti) {
        canvas.save();
        canvas.translate(p.position.dx, p.position.dy);
        canvas.rotate(p.life * pi * 4);
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.5,
          height: p.size,
        );
        canvas.drawRect(rect, paint);
        canvas.restore();
      } else {
        canvas.drawCircle(p.position, p.size, paint);
      }
    }
  }

  void _draw3DBall(
    Canvas canvas,
    Offset position,
    Color color,
    double scale, {
    double opacity = 1.0,
  }) {
    final double radius = GameConstants.ballRadius * scale;
    if (radius <= 0) return;

    // 1. Soft matte drop shadow offset below the ball
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.24 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(position + const Offset(0.0, 2.5), radius, shadowPaint);

    // 2. Radial gradient for subtle flat 3D depth
    final hsl = HSLColor.fromColor(color);
    final lightColor = hsl
        .withLightness((hsl.lightness + 0.05).clamp(0.0, 1.0))
        .toColor();
    final darkColor = hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          lightColor.withValues(alpha: opacity),
          color.withValues(alpha: opacity),
          darkColor.withValues(alpha: opacity),
        ],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: position, radius: radius));

    canvas.drawCircle(position, radius, paint);

    // Subtle dark border ring
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(position, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
