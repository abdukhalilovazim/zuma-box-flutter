import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
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

enum GameState { intro, playing, paused, gameOver, levelComplete }

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

  // Active theme
  String currentTheme = "tokyo";

  // Path data
  List<Offset> pathPoints = [];
  List<double> pathDistances = [];
  double totalPathLength = 0.0;
  Path? trackPath;
  ui.Picture? cachedTrackPicture;

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
  int ballsSpawned = 0;
  List<Color> levelColorPool = [];
  int colorPoolIndex = 0;
  int get maxLevelBalls => levelColorPool.length;

  // Ticker for game loop
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  // Notifier specifically for the canvas repaints
  final ValueNotifier<double> tickNotifier = ValueNotifier(0.0);

  GameController({required this.storageService}) {
    currentLevelNumber = storageService.getCurrentLevel();
    currentTheme = storageService.getTheme();
    // Pre-initialize to Level 1
    _loadLevel(currentLevelNumber);
  }

  void _generateLevelColorPool() {
    levelColorPool.clear();
    colorPoolIndex = 0;

    final boxDemand = currentLevelConfig.boxDemand;
    final colorCount = currentLevelConfig.colorCount;

    // Calculate max level balls closest to 60 that is a multiple of boxDemand
    final maxBalls = (60 ~/ boxDemand) * boxDemand;

    int totalGroups = maxBalls ~/ boxDemand;
    List<int> groupsPerColor = List.filled(colorCount, 0);

    for (int i = 0; i < totalGroups; i++) {
      groupsPerColor[i % colorCount]++;
    }

    List<Color> colorsToShuffle = [];
    for (int i = 0; i < colorCount; i++) {
      final color = GameConstants.getLevelColor(i, theme: currentTheme);
      final count = groupsPerColor[i] * boxDemand;
      for (int c = 0; c < count; c++) {
        colorsToShuffle.add(color);
      }
    }

    colorsToShuffle.shuffle(_random);
    levelColorPool.addAll(colorsToShuffle);
  }

  void _generateTrackPathAndPicture() {
    if (pathPoints.isEmpty) return;

    final path = Path();
    path.moveTo(pathPoints.first.dx, pathPoints.first.dy);
    for (int i = 1; i < pathPoints.length; i++) {
      path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
    }
    trackPath = path;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final themeColor = GameConstants.getLevelColor(
      currentLevelNumber - 1,
      theme: currentTheme,
    );
    Color glowColor = themeColor.withValues(alpha: 0.12);
    Color railColor = themeColor.withValues(alpha: 0.3);
    Color innerColor = const Color(0xFF0F0F1A);

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 46.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawPath(path, glowPaint);

    final railPaint = Paint()
      ..color = railColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, railPaint);

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, innerPaint);

    cachedTrackPicture = recorder.endRecording();
  }

  void _loadLevel(int levelNum) {
    currentLevelNumber = levelNum;
    final levels = LevelConfig.defaultLevels;
    currentLevelConfig = levels.firstWhere(
      (l) => l.levelNumber == levelNum,
      orElse: () => levels.first,
    );

    // Generate spline path using SCALED control points to prevent clipping
    pathPoints = PathManager.generateSmoothPath(
      currentLevelConfig.scaledControlPoints,
    );
    pathDistances = PathManager.computeCumulativeDistances(pathPoints);
    totalPathLength = pathDistances.isNotEmpty ? pathDistances.last : 0.0;

    _generateTrackPathAndPicture();

    // Generate color pool
    _generateLevelColorPool();

    // Reset game counters
    activeBalls.clear();
    flyingBalls.clear();
    particles.clear();
    tapEffects.clear();
    totalElapsedTime = 0.0;
    boxesCleared = 0;
    final int initialCount = min(15, maxLevelBalls);
    ballsSpawned = initialCount;

    // Prepare Intro state: spawn initial balls queued behind the entrance line from color pool
    state = GameState.intro;

    for (int i = 0; i < initialCount; i++) {
      final color = levelColorPool[colorPoolIndex++];
      final id = "init_${i}_${_random.nextInt(1000)}";
      double dist = -i * GameConstants.ballDiameter;
      activeBalls.add(
        Ball(
          id: id,
          color: color,
          distance: dist,
          targetDistance: dist,
          visualScale: 1.0,
        ),
      );
      // Pre-cache position/angle
      final posAngle = PathManager.getPositionAtDistance(
        dist,
        pathPoints,
        pathDistances,
      );
      activeBalls.last.currentPos = posAngle.position;
      activeBalls.last.currentAngle = posAngle.angle;
    }

    // Initialize Box with SCALED box position and target color from active balls
    final initialColor = _getRandomActiveColor(choosingNew: true);
    box = BoxModel(
      targetColor: initialColor,
      requiredCount: currentLevelConfig.boxDemand,
      position: currentLevelConfig.scaledBoxPosition,
    );

    _safeNotifyListeners();
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
    _safeNotifyListeners();
  }

  void pauseGame() {
    state = GameState.paused;
    _ticker?.stop();
    _safeNotifyListeners();
  }

  void resumeGame() {
    state = GameState.playing;
    _ticker?.start();
    _safeNotifyListeners();
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
    tickNotifier.dispose();
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

    // Ensure box target color is always solvable and valid (no remainder issues)
    if (state == GameState.playing && box != null && activeBalls.isNotEmpty) {
      final remainingDemand = box!.requiredCount - box!.currentCount;
      if (!_isColorValidForBox(
        box!.targetColor,
        currentCount: box!.currentCount,
        remainingDemand: remainingDemand,
      )) {
        // Before resetting, ensure there is AT LEAST ONE valid color available.
        // Otherwise, stick with the current color to avoid infinite flickering.
        final activeColors = activeBalls.map((b) => b.color).toSet().toList();
        bool hasAnyValid = false;
        for (var c in activeColors) {
          if (_isColorValidForBox(
            c,
            currentCount: 0,
            remainingDemand: box!.requiredCount,
          )) {
            hasAnyValid = true;
            break;
          }
        }

        if (hasAnyValid) {
          box!.reset(_getRandomActiveColor(choosingNew: true));
        }
      }
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

    // Notify the canvas to repaint
    tickNotifier.value = totalElapsedTime;
  }

  void _updateIntro(double dt) {
    if (activeBalls.isEmpty) {
      state = GameState.playing;
      return;
    }

    // Move head ball forward along the path rapidly (slither-in train entry)
    final double dynamicMultiplier =
        currentLevelConfig.speedMultiplier + (currentLevelNumber * 0.04);
    final double introSpeed = 220.0 * dynamicMultiplier;
    final head = activeBalls.first;
    head.targetDistance += introSpeed * dt;

    // Follow the leader snap logic
    for (int i = 1; i < activeBalls.length; i++) {
      activeBalls[i].targetDistance =
          activeBalls[i - 1].targetDistance - GameConstants.ballDiameter;
    }

    // Smoothly interpolate each ball's position
    for (int i = 0; i < activeBalls.length; i++) {
      final ball = activeBalls[i];
      final double diff = ball.targetDistance - ball.distance;

      if (diff.abs() < 0.1) {
        ball.distance = ball.targetDistance;
      } else {
        ball.distance += diff * 0.15;
      }

      final posAngle = PathManager.getPositionAtDistance(
        ball.distance,
        pathPoints,
        pathDistances,
      );
      ball.currentPos = posAngle.position;
      ball.currentAngle = posAngle.angle;
    }

    // When the last ball is completely on the visible path, start playing!
    if (activeBalls.last.distance >= 0.0) {
      state = GameState.playing;
    }
  }

  void _updatePlaying(double dt) {
    if (activeBalls.isEmpty) {
      if (ballsSpawned < maxLevelBalls) {
        // Spawn the first ball
        _spawnNewBall(0.0);
      } else if (flyingBalls.isEmpty) {
        // LEVEL COMPLETE!
        state = GameState.levelComplete;
        _ticker?.stop();
        storageService.setBestScore(score);
        // Unlock next level
        storageService.unlockLevel(currentLevelNumber + 1);
        storageService.completeLevel(currentLevelNumber);
        _createVictoryConfetti();
        _safeNotifyListeners();
        return;
      }
    } else {
      // Move head ball forward along the path
      final double dynamicMultiplier =
          currentLevelConfig.speedMultiplier + (currentLevelNumber * 0.04);
      final double normalSpeed = 35.0 * dynamicMultiplier;
      final head = activeBalls.first;
      head.targetDistance += normalSpeed * dt;

      // Make all other balls follow the target distance of the ball in front
      for (int i = 1; i < activeBalls.length; i++) {
        activeBalls[i].targetDistance =
            activeBalls[i - 1].targetDistance - GameConstants.ballDiameter;
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
        final posAngle = PathManager.getPositionAtDistance(
          ball.distance,
          pathPoints,
          pathDistances,
        );
        ball.currentPos = posAngle.position;
        ball.currentAngle = posAngle.angle;

        // Apply scale effect for emerging balls
        if (ball.distance < 0) {
          double visualScale =
              (ball.distance + GameConstants.ballRadius) /
              GameConstants.ballRadius;
          ball.visualScale = visualScale.clamp(0.0, 1.0);
        } else {
          ball.visualScale = 1.0;
        }
      }

      // Spawn a new ball at the tail when the tail ball has moved far enough from the start
      final tail = activeBalls.last;
      if (tail.distance > GameConstants.ballDiameter &&
          ballsSpawned < maxLevelBalls) {
        _spawnNewBall(tail.targetDistance - GameConstants.ballDiameter);
      }

      // Game Over Check: If head ball reaches the end of the path (which is the Box)
      if (head.distance >= totalPathLength) {
        state = GameState.gameOver;
        _ticker?.stop();
        _createGameOverExplosion();
        _safeNotifyListeners();
      }
    }
  }

  void _spawnNewBall(double targetDist) {
    if (ballsSpawned >= maxLevelBalls) return;
    ballsSpawned++;
    final id =
        "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100)}";
    final color = levelColorPool[colorPoolIndex++];
    activeBalls.add(
      Ball(
        id: id,
        color: color,
        distance: targetDist,
        targetDistance: targetDist,
        visualScale: 0.0,
      ),
    );
  }

  bool _isColorValidForBox(
    Color color, {
    required int currentCount,
    required int remainingDemand,
  }) {
    int activeCount = activeBalls.where((b) => b.color == color).length;
    int flyingCount = flyingBalls.where((b) => b.color == color).length;
    int totalAvailable = activeCount + flyingCount;
    if (totalAvailable == 0) return false;

    if (ballsSpawned < maxLevelBalls) {
      return true;
    }

    // Line has ended (spawning is complete)
    final boxDemand = currentLevelConfig.boxDemand;
    if (currentCount > 0 || flyingCount > 0) {
      // We are in the middle of filling this box. We just need enough balls (on path + in air) to complete it.
      return totalAvailable >= remainingDemand;
    } else {
      // We are choosing a new color. The active count must be a multiple of boxDemand.
      return activeCount >= boxDemand && (activeCount % boxDemand == 0);
    }
  }

  Color _getRandomActiveColor({bool choosingNew = false}) {
    if (activeBalls.isEmpty) {
      return GameConstants.getLevelColor(
        _random.nextInt(currentLevelConfig.colorCount),
        theme: currentTheme,
      );
    }

    final boxDemand = currentLevelConfig.boxDemand;
    final currentCount = (box != null && !choosingNew) ? box!.currentCount : 0;
    final remainingDemand = (box != null && !choosingNew)
        ? (box!.requiredCount - box!.currentCount)
        : boxDemand;

    List<Color> validColors = [];
    final activeColors = activeBalls.map((b) => b.color).toSet().toList();

    for (var color in activeColors) {
      if (_isColorValidForBox(
        color,
        currentCount: currentCount,
        remainingDemand: remainingDemand,
      )) {
        int activeCount = activeBalls.where((b) => b.color == color).length;
        if (activeCount >= remainingDemand) {
          validColors.add(color);
        }
      }
    }

    if (validColors.isNotEmpty) {
      return validColors[_random.nextInt(validColors.length)];
    }

    // Fallback: If no color has enough balls on screen, pick any valid color
    List<Color> fallbackColors = [];
    for (var color in activeColors) {
      if (_isColorValidForBox(
        color,
        currentCount: currentCount,
        remainingDemand: remainingDemand,
      )) {
        fallbackColors.add(color);
      }
    }

    if (fallbackColors.isNotEmpty) {
      return fallbackColors[_random.nextInt(fallbackColors.length)];
    }

    return activeColors[_random.nextInt(activeColors.length)];
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

    final id =
        "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(100)}";
    activeBalls.add(
      Ball(
        id: id,
        color: color,
        distance: 0.0,
        targetDistance: 0.0,
        visualScale: 1.0,
      ),
    );

    // Set cached position instantly for smooth visual entry
    final posAngle = PathManager.getPositionAtDistance(
      0.0,
      pathPoints,
      pathDistances,
    );
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

      // Reset Box with a new target color
      final newColor = _getRandomActiveColor(choosingNew: true);
      box!.reset(newColor);
      _safeNotifyListeners(); // Notify UI of score/box update
    } else {
      // Normal hit: spark burst
      _createHitSparks(ball.endPosition, ball.color);
      HapticFeedback.mediumImpact();
      _safeNotifyListeners(); // Notify UI of score update
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
        int flyingOfTargetColor = flyingBalls
            .where((b) => b.color == box!.targetColor)
            .length;
        int remainingDemand = box!.requiredCount - box!.currentCount;

        if (flyingOfTargetColor < remainingDemand) {
          // CORRECT TAP:
          HapticFeedback.lightImpact();
          tapEffects.add(
            TapEffect(
              position: tappedBall.currentPos,
              color: Colors.white,
              isCorrect: true,
            ),
          );

          // DETACH FROM CHAIN
          activeBalls.removeAt(hitIndex);

          // Shift backward by 1 diameter. Let's make it a snappy shift!
          for (int i = 0; i < hitIndex; i++) {
            activeBalls[i].targetDistance -= GameConstants.ballDiameter;
          }

          // CREATE FLYING BALL
          // Curve path: midpoint + perpendicular displacement
          final startPos = tappedBall.currentPos;
          double slotSpacing = 36.0;
          double startX =
              box!.position.dx - ((box!.requiredCount - 1) * slotSpacing) / 2;
          // Calculate destination slot based on already filled + currently flying
          int targetSlotIndex = box!.currentCount + flyingOfTargetColor;
          final endPos = Offset(
            startX + (targetSlotIndex * slotSpacing),
            box!.position.dy,
          );
          final mid = (startPos + endPos) / 2;
          final dir = endPos - startPos;
          // Generate a random curve height offset to the left or right
          final perpSign = _random.nextBool() ? 1 : -1;
          final perp = Offset(-dir.dy, dir.dx).normalize() * (70.0 * perpSign);
          final control = mid + perp;

          flyingBalls.add(
            FlyingBall(
              id: tappedBall.id,
              color: tappedBall.color,
              startPosition: startPos,
              endPosition: endPos,
              controlPoint: control,
            ),
          );
        } else {
          // WRONG TAP (Box already has enough balls flying towards it)
          HapticFeedback.vibrate();
          tappedBall.shakeTimer = 0.25;
          tapEffects.add(
            TapEffect(
              position: tappedBall.currentPos,
              color: GameConstants.neonRed,
              isCorrect: false,
            ),
          );
        }
      } else {
        // WRONG TAP:
        HapticFeedback.vibrate();
        tappedBall.shakeTimer = 0.25; // Subtle shake duration
        tapEffects.add(
          TapEffect(
            position: tappedBall.currentPos,
            color: GameConstants.neonRed,
            isCorrect: false,
          ),
        );
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
      particles.add(
        GameParticle(
          position: origin,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color.withValues(alpha: 0.8),
          size: 3.0 + _random.nextDouble() * 3.0,
          maxLife: 0.4 + _random.nextDouble() * 0.3,
        ),
      );
    }
  }

  void _createBoxClearParticles(Offset origin, Color color) {
    // 30 bright multi-colored neon particles
    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 120.0 + _random.nextDouble() * 200.0;
      final sparkColor = _random.nextBool()
          ? color
          : GameConstants.getLevelColor(
              _random.nextInt(5),
              theme: currentTheme,
            );
      particles.add(
        GameParticle(
          position: origin,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: sparkColor,
          size: 4.0 + _random.nextDouble() * 5.0,
          maxLife: 0.6 + _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  void _createGameOverExplosion() {
    if (activeBalls.isEmpty) return;
    final headPos = activeBalls.first.currentPos;
    for (int i = 0; i < 50; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 50.0 + _random.nextDouble() * 250.0;
      particles.add(
        GameParticle(
          position: headPos,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: Colors.redAccent,
          size: 4.0 + _random.nextDouble() * 6.0,
          maxLife: 0.8 + _random.nextDouble() * 0.6,
        ),
      );
    }
  }

  void _createVictoryConfetti() {
    // Spawn falling confetti across the screen
    for (int i = 0; i < 80; i++) {
      final startX = _random.nextDouble() * GameConstants.logicalWidth;
      final startY = -_random.nextDouble() * 100.0; // Spawn offscreen top
      final speedY = 100.0 + _random.nextDouble() * 150.0;
      final speedX = -40.0 + _random.nextDouble() * 80.0;
      final confColor = GameConstants.getLevelColor(
        _random.nextInt(5),
        theme: currentTheme,
      );
      particles.add(
        GameParticle(
          position: Offset(startX, startY),
          velocity: Offset(speedX, speedY),
          color: confColor,
          size: 5.0 + _random.nextDouble() * 6.0,
          maxLife: 2.0 + _random.nextDouble() * 1.5,
          isConfetti: true,
        ),
      );
    }
  }

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  String get currentLanguage => storageService.getLanguage();

  void setLanguage(String lang) {
    storageService.setLanguage(lang);
    _safeNotifyListeners();
  }

  void setTheme(String theme) {
    currentTheme = theme;
    storageService.setTheme(theme);
    _safeNotifyListeners();
  }

  static const Map<String, Map<String, String>> _translations = {
    "uz": {
      "best_score": "ENG YAXSHI NATIJA",
      "start_game": "O'YINNI BOSHLASH",
      "select_level": "DARAJANI TANLANG",
      "left": "TA QOLDI",
      "score": "BALL",
      "paused": "PAUZA",
      "resume": "DAVOM ETISH",
      "restart": "QAYTADAN BOSHLASH",
      "main_menu": "ASOSIY MENU",
      "game_over": "O'YIN TUGADI",
      "try_again": "QAYTADAN URINISH",
      "level_complete": "DARAJA YAKUNLANDI",
      "final_score": "YAKUNIY BALL",
      "next_level": "KEYINGI DARAJA",
      "all_cleared": "SIZ BARCHA DARAJALARDAN O'TDINGIZ!",
      "level": "DARAJA",
      "select_theme": "TEMA TANLANG",
      "tokyo": "TOKYO",
      "germany": "GERMANIYA",
      "egypt": "MISR",
      "elephant": "FILLAR QABRISTONI",
    },
    "ru": {
      "best_score": "ЛУЧШИЙ РЕЗУЛЬТАТ",
      "start_game": "НАЧАТЬ ИГРУ",
      "select_level": "ВЫБЕРИТЕ УРОВЕНЬ",
      "left": "ОСТАЛОСЬ",
      "score": "СЧЕТ",
      "paused": "ПАУЗА",
      "resume": "ПРОДОЛЖИТЬ",
      "restart": "НАЧАТЬ ЗАНОВО",
      "main_menu": "ГЛАВНОЕ МЕНЮ",
      "game_over": "ИГРА ОКОНЧЕНА",
      "try_again": "ЕЩЕ РАЗ",
      "level_complete": "УРОВЕНЬ ПРОЙДЕН",
      "final_score": "ИТОГОВЫЙ СЧЕТ",
      "next_level": "СЛЕДУЮЩИЙ УРОВЕНЬ",
      "all_cleared": "ВЫ ПРОШЛИ ВСЕ УРОВНИ!",
      "level": "УРОВЕНЬ",
      "select_theme": "ВЫБЕРИТЕ ТЕМУ",
      "tokyo": "ТОКИО",
      "germany": "ГЕРМАНИЯ",
      "egypt": "ЕГИПЕТ",
      "elephant": "КЛАДБИЩЕ СЛОНОВ",
    },
    "en": {
      "best_score": "BEST SCORE",
      "start_game": "START GAME",
      "select_level": "SELECT LEVEL",
      "left": "LEFT",
      "score": "SCORE",
      "paused": "PAUSED",
      "resume": "RESUME",
      "restart": "RESTART",
      "main_menu": "MAIN MENU",
      "game_over": "GAME OVER",
      "try_again": "TRY AGAIN",
      "level_complete": "LEVEL COMPLETE",
      "final_score": "FINAL SCORE",
      "next_level": "NEXT LEVEL",
      "all_cleared": "YOU CLEARED ALL LEVELS!",
      "level": "LEVEL",
      "select_theme": "SELECT THEME",
      "tokyo": "TOKYO",
      "germany": "GERMANY",
      "egypt": "EGYPT",
      "elephant": "ELEPHANT GRAVEYARD",
    },
  };

  String translate(String key) {
    return _translations[currentLanguage]?[key] ??
        _translations["uz"]?[key] ??
        key;
  }
}

extension OffsetNormalize on Offset {
  Offset normalize() {
    double len = distance;
    if (len == 0.0) return Offset.zero;
    return Offset(dx / len, dy / len);
  }
}
