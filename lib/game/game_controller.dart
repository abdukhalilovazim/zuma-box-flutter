import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../models/ball.dart';
import '../models/box.dart';
import '../models/level.dart';
import '../utils/constants.dart';
import '../utils/storage_service.dart';
import 'collision_detector.dart';
import 'path_manager.dart';

class TapEffect {
  final Offset position;
  final Color color;
  final bool isCorrect;
  double t = 0.0; // 0.0 to 1.0

  TapEffect({
    required this.position,
    required this.color,
    required this.isCorrect,
  });
}

enum GameState {
  intro,
  playing,
  paused,
  gameOver,
  levelComplete,
}

class GameParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double opacity;
  double life; // 1.0 to 0.0
  final double maxLife;
  final bool isConfetti;

  GameParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.opacity = 1.0,
    this.life = 1.0,
    this.maxLife = 1.0,
    this.isConfetti = false,
  });
}

class GameController extends ChangeNotifier {
  final StorageService storageService;
  final Random _random = Random();

  // Active level config
  late LevelConfig currentLevelConfig;
  int currentLevelNumber = 1;

  // Path data
  List<Offset> pathPoints = [];
  List<double> pathDistances = [];
  double totalPathLength = 0.0;

  // Game entities
  List<Ball> activeBalls = [];
  List<FlyingBall> flyingBalls = [];
  BoxModel? box;

  // Particles & Visual effects
  List<GameParticle> particles = [];
  List<TapEffect> tapEffects = [];
  double totalElapsedTime = 0.0;

  // Game State
  GameState state = GameState.paused;
  int score = 0;
  int boxesCleared = 0;
  static const int boxesRequiredToComplete = 10;

  // Ticker for game loop
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  // Intro Animation variables
  List<Ball> introBalls = [];
  double introTimer = 0.0;
  static const double introScaleDuration = 1.0;
  static const double introLaunchInterval = 0.18;
  int introLaunchedCount = 0;
  double introLaunchTimer = 0.0;

  GameController({required this.storageService}) {
    currentLevelNumber = storageService.getCurrentLevel();
    // Pre-initialize to Level 1
    _loadLevel(currentLevelNumber);
  }

  void _loadLevel(int levelNum) {
    currentLevelNumber = levelNum;
    final levels = LevelConfig.defaultLevels;
    currentLevelConfig = levels.firstWhere(
      (l) => l.levelNumber == levelNum,
      orElse: () => levels.first,
    );

    // Generate spline path
    pathPoints = PathManager.generateSmoothPath(currentLevelConfig.controlPoints);
    pathDistances = PathManager.computeCumulativeDistances(pathPoints);
    totalPathLength = pathDistances.isNotEmpty ? pathDistances.last : 0.0;

    // Initialize Box
    final initialColor = GameConstants.getLevelColor(_random.nextInt(currentLevelConfig.colorCount));
    box = BoxModel(
      targetColor: initialColor,
      requiredCount: currentLevelConfig.boxDemand,
      position: currentLevelConfig.boxPosition,
    );

    // Reset game counters
    activeBalls.clear();
    flyingBalls.clear();
    particles.clear();
    tapEffects.clear();
    totalElapsedTime = 0.0;
    introBalls.clear();
    boxesCleared = 0;
    
    // Prepare Intro state
    state = GameState.intro;
    introTimer = 0.0;
    introLaunchTimer = 0.0;
    introLaunchedCount = 0;
    
    _setupIntroTriangle();
    notifyListeners();
  }

  void _setupIntroTriangle() {
    // Generate 10 balls arranged in a triangle in the center of the canvas (400x700)
    // Row 1: 1 ball
    // Row 2: 2 balls
    // Row 3: 3 balls
    // Row 4: 4 balls
    final List<Offset> trianglePositions = [
      // Row 1
      const Offset(200, 260),
      // Row 2
      const Offset(183, 290), const Offset(217, 290),
      // Row 3
      const Offset(166, 320), const Offset(200, 320), const Offset(234, 320),
      // Row 4
      const Offset(149, 350), const Offset(183, 350), const Offset(217, 350), const Offset(251, 350),
    ];

    for (int i = 0; i < trianglePositions.length; i++) {
      final color = GameConstants.getLevelColor(_random.nextInt(currentLevelConfig.colorCount));
      final ball = Ball(
        id: "intro_$i",
        color: color,
        distance: 0.0,
        targetDistance: 0.0,
        visualScale: 0.0, // Start scaled down
      );
      ball.currentPos = trianglePositions[i];
      introBalls.add(ball);
    }
  }

  // Starts or resumes the game loop Ticker
  void startGame() {
    _ticker?.dispose();
    _ticker = Ticker(_onTick);
    _lastElapsed = Duration.zero;
    _ticker!.start();
    if (state == GameState.paused) {
      state = GameState.playing;
    }
    notifyListeners();
  }

  void pauseGame() {
    state = GameState.paused;
    _ticker?.stop();
    notifyListeners();
  }

  void resumeGame() {
    state = GameState.playing;
    _ticker?.start();
    notifyListeners();
  }

  void restartLevel() {
    _loadLevel(currentLevelNumber);
    startGame();
  }

  void startLevel(int levelNum) {
    storageService.setCurrentLevel(levelNum);
    _loadLevel(levelNum);
    startGame();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Cap delta time to prevent physics glitches on frame drops
    final double cappedDt = dt.clamp(0.0, 0.05);

    update(cappedDt);
  }

  void update(double dt) {
    if (state == GameState.paused) return;

    totalElapsedTime += dt;

    // Update Tap Effects
    for (int i = tapEffects.length - 1; i >= 0; i--) {
      tapEffects[i].t += dt / 0.35;
      if (tapEffects[i].t >= 1.0) {
        tapEffects.removeAt(i);
      }
    }

    // Update Ball shake timers
    for (var ball in activeBalls) {
      if (ball.shakeTimer > 0.0) {
        ball.shakeTimer -= dt;
        if (ball.shakeTimer < 0.0) ball.shakeTimer = 0.0;
      }
    }

    // 1. Update Particles
    _updateParticles(dt);

    // 2. State-specific Updates
    if (state == GameState.intro) {
      _updateIntro(dt);
    } else if (state == GameState.playing) {
      _updatePlaying(dt);
    }

    // 3. Update Flying Balls
    _updateFlyingBalls(dt);

    // 4. Update Box Animations
    if (box != null) {
      if (box!.bounceScale > 1.0) {
        box!.bounceScale -= dt * 2.0;
        if (box!.bounceScale < 1.0) box!.bounceScale = 1.0;
      }
      if (box!.explosionOpacity > 0.0) {
        box!.explosionScale += dt * 3.0;
        box!.explosionOpacity -= dt * 2.5;
        if (box!.explosionOpacity < 0.0) {
          box!.explosionOpacity = 0.0;
          box!.explosionScale = 0.0;
        }
      }
    }

    notifyListeners();
  }

  void _updateIntro(double dt) {
    introTimer += dt;

    if (introTimer <= introScaleDuration) {
      // Phase 1: Scale up the bowling pins triangle
      double progress = (introTimer / introScaleDuration).clamp(0.0, 1.0);
      for (var ball in introBalls) {
        ball.visualScale = progress;
      }
    } else {
      // Phase 2: Launch them one by one into the start of the path
      for (var ball in introBalls) {
        ball.visualScale = 1.0;
      }

      introLaunchTimer += dt;
      if (introLaunchedCount < introBalls.length && introLaunchTimer >= introLaunchInterval) {
        introLaunchTimer = 0.0;
        final ballToLaunch = introBalls[introLaunchedCount];
        introLaunchedCount++;

        // Calculate control point for a beautiful arc from triangle to path start
        final startOffset = ballToLaunch.currentPos;
        final endOffset = pathPoints.first;
        final midPoint = (startOffset + endOffset) / 2;
        // Offset perpendicular to create arc
        final dir = endOffset - startOffset;
        final perp = Offset(-dir.dy, dir.dx).normalize() * 80.0;
        final control = midPoint + perp;

        flyingBalls.add(FlyingBall(
          id: "intro_launch_${ballToLaunch.id}",
          color: ballToLaunch.color,
          startPosition: startOffset,
          endPosition: endOffset,
          controlPoint: control,
          t: 0.0,
        ));
      }

      // If all intro balls have launched and all intro flying balls are completed, start game
      if (introLaunchedCount >= introBalls.length && flyingBalls.isEmpty) {
        state = GameState.playing;
      }
    }
  }

  void _updatePlaying(double dt) {
    if (activeBalls.isEmpty) {
      // Spawn the first ball
      _spawnNewBall(0.0);
    } else {
      // Move head ball forward along the path
      final double normalSpeed = 35.0 * currentLevelConfig.speedMultiplier;
      final head = activeBalls.first;
      head.targetDistance += normalSpeed * dt;

      // Make all other balls follow the target distance of the ball in front
      for (int i = 1; i < activeBalls.length; i++) {
        activeBalls[i].targetDistance = activeBalls[i - 1].targetDistance - GameConstants.ballDiameter;
      }

      // Smoothly interpolate each ball's physical position towards its target distance
      for (int i = 0; i < activeBalls.length; i++) {
        final ball = activeBalls[i];
        final double diff = ball.targetDistance - ball.distance;

        if (diff.abs() < 0.1) {
          ball.distance = ball.targetDistance;
        } else {
          // Rapidly catch up or slide back
          ball.distance += diff * 12.0 * dt;
        }

        // Cache positions for drawing and collision checks
        final posAngle = PathManager.getPositionAtDistance(ball.distance, pathPoints, pathDistances);
        ball.currentPos = posAngle.position;
        ball.currentAngle = posAngle.angle;

        // Apply scale effect for emerging balls
        if (ball.distance < 0) {
          double visualScale = (ball.distance + GameConstants.ballRadius) / GameConstants.ballRadius;
          ball.visualScale = visualScale.clamp(0.0, 1.0);
        } else {
          ball.visualScale = 1.0;
        }
      }

      // Spawn a new ball at the tail when the tail ball has moved far enough from the start
      final tail = activeBalls.last;
      if (tail.distance > GameConstants.ballDiameter) {
        _spawnNewBall(tail.targetDistance - GameConstants.ballDiameter);
      }

      // Game Over Check: If head ball reaches the end of the path (which is the Box)
      if (head.distance >= totalPathLength) {
        state = GameState.gameOver;
        _ticker?.stop();
        _createGameOverExplosion();
      }
    }
  }

  void _spawnNewBall(double targetDist) {
    final id = DateTime.now().microsecondsSinceEpoch.toString() + "_${_random.nextInt(100)}";
    final color = _getRandomActiveColor();
    activeBalls.add(Ball(
      id: id,
      color: color,
      distance: targetDist,
      targetDistance: targetDist,
      visualScale: 0.0,
    ));
  }

  Color _getRandomActiveColor() {
    // DEADLOCK PREVENTION: 
    // If the chain is active, pick from colors currently in the chain to keep it solvable.
    if (activeBalls.isNotEmpty) {
      final currentColors = activeBalls.map((b) => b.color).toSet().toList();
      if (currentColors.isNotEmpty) {
        return currentColors[_random.nextInt(currentColors.length)];
      }
    }
    return GameConstants.getLevelColor(_random.nextInt(currentLevelConfig.colorCount));
  }

  void _updateFlyingBalls(double dt) {
    for (int i = flyingBalls.length - 1; i >= 0; i--) {
      final flyBall = flyingBalls[i];
      // Flying speed: takes ~0.35 seconds
      flyBall.t += dt / 0.35;

      if (flyBall.t >= 1.0) {
        flyBall.t = 1.0;
        flyingBalls.removeAt(i);

        if (state == GameState.intro) {
          // If it was an intro flying ball, it reached the start of the path
          _addBallToChainTail(flyBall.color);
        } else {
          // Gameplay flying ball: reached the Box!
          _onBallLandedInBox(flyBall);
        }
      }
    }
  }

  void _addBallToChainTail(Color color) {
    // Shift all existing target distances to make room at the tail
    for (var ball in activeBalls) {
      ball.distance += GameConstants.ballDiameter;
      ball.targetDistance += GameConstants.ballDiameter;
    }
    
    final id = DateTime.now().microsecondsSinceEpoch.toString() + "_${_random.nextInt(100)}";
    activeBalls.add(Ball(
      id: id,
      color: color,
      distance: 0.0,
      targetDistance: 0.0,
      visualScale: 1.0,
    ));
    
    // Set cached position instantly for smooth visual entry
    final posAngle = PathManager.getPositionAtDistance(0.0, pathPoints, pathDistances);
    activeBalls.last.currentPos = posAngle.position;
    activeBalls.last.currentAngle = posAngle.angle;
  }

  void _onBallLandedInBox(FlyingBall ball) {
    if (box == null) return;
    
    score += 10;
    bool boxCompleted = box!.addBall();

    if (boxCompleted) {
      boxesCleared++;
      score += 100;
      _createBoxClearParticles(box!.position, ball.color);
      HapticFeedback.heavyImpact();

      if (boxesCleared >= boxesRequiredToComplete) {
        // LEVEL COMPLETE!
        state = GameState.levelComplete;
        _ticker?.stop();
        storageService.setBestScore(score);
        // Unlock next level
        storageService.unlockLevel(currentLevelNumber + 1);
        _createVictoryConfetti();
      } else {
        // Reset Box with a new target color
        final newColor = _getRandomActiveColor();
        box!.reset(newColor);
      }
    } else {
      // Normal hit: spark burst
      _createHitSparks(box!.position, ball.color);
      HapticFeedback.mediumImpact();
    }
  }

  void handleTap(Offset logicalTapPos) {
    if (state != GameState.playing) return;

    final hitIndex = CollisionDetector.detectTappedBall(
      logicalTapPos: logicalTapPos,
      activeBalls: activeBalls,
      ballRadius: GameConstants.ballRadius,
    );

    if (hitIndex != null) {
      final tappedBall = activeBalls[hitIndex];

      // Verifying if color matches the Box target color
      if (box != null && tappedBall.color == box!.targetColor) {
        // CORRECT TAP:
        HapticFeedback.lightImpact();
        tapEffects.add(TapEffect(
          position: tappedBall.currentPos,
          color: Colors.white,
          isCorrect: true,
        ));

        // DETACH FROM CHAIN
        activeBalls.removeAt(hitIndex);

        // Shift backward by 1 diameter. Let's make it a snappy shift!
        for (int i = 0; i < hitIndex; i++) {
          activeBalls[i].targetDistance -= GameConstants.ballDiameter;
        }

        // CREATE FLYING BALL
        // Curve path: midpoint + perpendicular displacement
        final startPos = tappedBall.currentPos;
        final endPos = box!.position;
        final mid = (startPos + endPos) / 2;
        final dir = endPos - startPos;
        // Generate a random curve height offset to the left or right
        final perpSign = _random.nextBool() ? 1 : -1;
        final perp = Offset(-dir.dy, dir.dx).normalize() * (70.0 * perpSign);
        final control = mid + perp;

        flyingBalls.add(FlyingBall(
          id: tappedBall.id,
          color: tappedBall.color,
          startPosition: startPos,
          endPosition: endPos,
          controlPoint: control,
        ));
      } else {
        // WRONG TAP:
        HapticFeedback.vibrate();
        tappedBall.shakeTimer = 0.25; // Subtle shake duration
        tapEffects.add(TapEffect(
          position: tappedBall.currentPos,
          color: GameConstants.neonRed,
          isCorrect: false,
        ));
      }
    }
  }

  // --- Particle Systems ---

  void _updateParticles(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life -= dt / p.maxLife;
      if (p.life <= 0.0) {
        particles.removeAt(i);
        continue;
      }

      // Physics integration
      p.position += p.velocity * dt;
      if (p.isConfetti) {
        // Gravity and drift
        p.velocity += const Offset(0.0, 150.0) * dt; // Gravity
        p.velocity = Offset(p.velocity.dx * 0.98, p.velocity.dy); // Air drag
      } else {
        // Exploding spark drag
        p.velocity *= 0.93;
      }
      p.opacity = p.life;
    }
  }

  void _createHitSparks(Offset origin, Color color) {
    for (int i = 0; i < 15; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 80.0 + _random.nextDouble() * 120.0;
      particles.add(GameParticle(
        position: origin,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color.withOpacity(0.8),
        size: 3.0 + _random.nextDouble() * 3.0,
        maxLife: 0.4 + _random.nextDouble() * 0.3,
      ));
    }
  }

  void _createBoxClearParticles(Offset origin, Color color) {
    // 30 bright multi-colored neon particles
    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 120.0 + _random.nextDouble() * 200.0;
      final sparkColor = _random.nextBool()
          ? color
          : GameConstants.getLevelColor(_random.nextInt(5));
      particles.add(GameParticle(
        position: origin,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: sparkColor,
        size: 4.0 + _random.nextDouble() * 5.0,
        maxLife: 0.6 + _random.nextDouble() * 0.5,
      ));
    }
  }

  void _createGameOverExplosion() {
    if (activeBalls.isEmpty) return;
    final headPos = activeBalls.first.currentPos;
    for (int i = 0; i < 50; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 50.0 + _random.nextDouble() * 250.0;
      particles.add(GameParticle(
        position: headPos,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: Colors.redAccent,
        size: 4.0 + _random.nextDouble() * 6.0,
        maxLife: 0.8 + _random.nextDouble() * 0.6,
      ));
    }
  }

  void _createVictoryConfetti() {
    // Spawn falling confetti across the screen
    for (int i = 0; i < 80; i++) {
      final startX = _random.nextDouble() * GameConstants.logicalWidth;
      final startY = -_random.nextDouble() * 100.0; // Spawn offscreen top
      final speedY = 100.0 + _random.nextDouble() * 150.0;
      final speedX = -40.0 + _random.nextDouble() * 80.0;
      final confColor = GameConstants.getLevelColor(_random.nextInt(5));
      particles.add(GameParticle(
        position: Offset(startX, startY),
        velocity: Offset(speedX, speedY),
        color: confColor,
        size: 5.0 + _random.nextDouble() * 6.0,
        maxLife: 2.0 + _random.nextDouble() * 1.5,
        isConfetti: true,
      ));
    }
  }
}

extension OffsetNormalize on Offset {
  Offset normalize() {
    double len = distance;
    if (len == 0.0) return Offset.zero;
    return Offset(dx / len, dy / len);
  }
}
