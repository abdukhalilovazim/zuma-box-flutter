import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final bestScore = controller.storageService.getBestScore();
    final unlockedLevels = controller.storageService.getUnlockedLevels();
    final completedLevels = controller.storageService.getCompletedLevels();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Cosmic Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return CustomPaint(
                painter: MenuBackgroundPainter(animationVal: _bgController.value),
                child: Container(),
              );
            },
          ),

          // Language Selector at Top Right
          Positioned(
            top: 20.0,
            right: 20.0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ["UZ", "RU", "EN"].map((lang) {
                    final isSelected = controller.currentLanguage == lang.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        controller.setLanguage(lang.toLowerCase());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: isSelected ? GameConstants.neonText : Colors.transparent,
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Text(
                          lang,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF12121F) : Colors.white70,
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // 2. Menu Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Pulsing Logo
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Text(
                          "ZUMA",
                          style: TextStyle(
                            fontSize: 66.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0.0, 4.0),
                                blurRadius: 8.0,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "BOX",
                          style: TextStyle(
                            fontSize: 38.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6.0,
                            color: GameConstants.neonText,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0.0, 4.0),
                                blurRadius: 8.0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24.0),

                // Best Score Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: GameConstants.neonText.withOpacity(0.15),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "${controller.translate('best_score')}: $bestScore",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: "monospace",
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Pulsing Play Button
                MenuPlayButton(
                  onTap: () {
                    final latestLevel = unlockedLevels.isNotEmpty
                        ? unlockedLevels.reduce((a, b) => a > b ? a : b)
                        : 1;
                    controller.startLevel(latestLevel);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                ),

                const Spacer(flex: 1),

                // Level Select Section
                Text(
                  controller.translate('select_level'),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Level Grid
                Container(
                  height: 140.0,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(overscroll: false),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 12.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: 30,
                      itemBuilder: (context, index) {
                        final levelNum = index + 1;
                        final isUnlocked = unlockedLevels.contains(levelNum);
                        final levelColor = GameConstants.getLevelColor(index % 5);

                        final isCompleted = completedLevels.contains(levelNum);

                        return GestureDetector(
                          onTap: isUnlocked
                              ? () {
                                  controller.startLevel(levelNum);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const GameScreen()),
                                  );
                                }
                              : null,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isUnlocked ? GameConstants.cardBg : Colors.black38,
                                  borderRadius: BorderRadius.circular(15.0),
                                  border: Border.all(
                                    color: isCompleted
                                        ? GameConstants.neonGreen.withOpacity(0.85)
                                        : (isUnlocked
                                            ? const Color(0xFF2C2C3E)
                                            : Colors.white10),
                                    width: isCompleted ? 2.0 : 1.5,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: isCompleted
                                                ? GameConstants.neonGreen.withOpacity(0.2)
                                                : Colors.black.withOpacity(0.15),
                                            blurRadius: 6.0,
                                            offset: const Offset(0.0, 2.0),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: isUnlocked
                                      ? Text(
                                          "$levelNum",
                                          style: TextStyle(
                                            color: isCompleted ? GameConstants.neonGreen : levelColor,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.lock_rounded,
                                          color: Colors.white24,
                                          size: 18.0,
                                        ),
                                ),
                              ),
                              if (isCompleted)
                                Positioned(
                                  top: -4.0,
                                  right: -4.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4.0,
                                        )
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 10.0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------
// Interactive Menu Play Button Widget
// ---------------------------------------------

class MenuPlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const MenuPlayButton({Key? key, required this.onTap}) : super(key: key);

  @override
  _MenuPlayButtonState createState() => _MenuPlayButtonState();
}

class _MenuPlayButtonState extends State<MenuPlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _btnController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _btnController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              decoration: BoxDecoration(
                color: GameConstants.neonText,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: GameConstants.neonText.withOpacity(0.28),
                    blurRadius: 16.0,
                    offset: const Offset(0.0, 4.0),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  Provider.of<GameController>(context).translate("start_game"),
                  style: const TextStyle(
                    color: Color(0xFF12121F),
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------
// Animated Background Painter
// ---------------------------------------------

class MenuBackgroundPainter extends CustomPainter {
  final double animationVal;

  MenuBackgroundPainter({required this.animationVal});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Warm deep charcoal dark background
    final bgPaint = Paint()..color = GameConstants.obsidianBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Drifting subtle geometric polygon shapes
    final polygonPaint = Paint()
      ..color = const Color(0xFF1E1E2E).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      double t = animationVal + (i * 0.25);
      double centerX = size.width * (0.2 + 0.6 * sin(t * pi * 2 + i));
      double centerY = size.height * (0.1 + 0.8 * (t % 1.0));
      double radius = 60.0 + i * 25.0;

      final path = Path();
      int sides = 3 + (i % 2); // Drift triangles and diamonds/squares
      for (int s = 0; s < sides; s++) {
        double angle = (s * 2 * pi / sides) + t * pi * 0.5;
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

  @override
  bool shouldRepaint(covariant MenuBackgroundPainter oldDelegate) =>
      oldDelegate.animationVal != animationVal;
}
