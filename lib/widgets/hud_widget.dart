import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';
import '../utils/constants.dart';

class HudWidget extends StatelessWidget {
  const HudWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);

    // Calculate level complete stars based on score
    int starsCount = 1;
    if (controller.score >= 1200) {
      starsCount = 3;
    } else if (controller.score >= 600) {
      starsCount = 2;
    }

    return Stack(
      children: [
        // 1. Top HUD Bar (Frosted glassmorphism pill)
        Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12.0,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Level Info
                        Expanded(
                          child: Text(
                            "${controller.translate('level')} ${controller.currentLevelNumber}  •  ${(controller.maxLevelBalls - controller.ballsSpawned).clamp(0, controller.maxLevelBalls)} ${controller.translate('left')}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Center Pause Button (Frosted dark circle)
                        GestureDetector(
                          onTap: () {
                            controller.pauseGame();
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.0),
                                ),
                                child: const Icon(
                                  Icons.pause,
                                  color: Colors.white70,
                                  size: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Score Pop counter
                        Expanded(
                          child: ScoreText(score: controller.score),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Pause Screen Overlay
        if (controller.state == GameState.paused)
          _buildScreenOverlay(
            context: context,
            title: controller.translate('paused'),
            titleColor: GameConstants.neonText,
            content: [
              _buildNeonButton(
                text: controller.translate('resume'),
                onPressed: () => controller.resumeGame(),
                color: GameConstants.neonText,
              ),
              const SizedBox(height: 15.0),
              _buildNeonButton(
                text: controller.translate('restart'),
                onPressed: () => controller.restartLevel(),
                color: GameConstants.neonYellow,
              ),
              const SizedBox(height: 15.0),
              _buildNeonButton(
                text: controller.translate('main_menu'),
                onPressed: () {
                  controller.pauseGame();
                  Navigator.of(context).pop();
                },
                color: Colors.white60,
              ),
            ],
          ),

        // 3. Game Over Screen Overlay (with red vignette and glitch text)
        if (controller.state == GameState.gameOver)
          Stack(
            children: [
              // Red vignette glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.red.withOpacity(0.35),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              _buildScreenOverlay(
                context: context,
                isGameOver: true,
                title: controller.translate('game_over'),
                titleColor: GameConstants.neonRed,
                score: controller.score,
                content: [
                  PulsingButton(
                    onPressed: () => controller.restartLevel(),
                    child: _buildNeonButtonRaw(
                      text: controller.translate('try_again'),
                      color: GameConstants.neonRed,
                    ),
                  ),
                  const SizedBox(height: 15.0),
                  _buildNeonButton(
                    text: controller.translate('main_menu'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    color: Colors.white60,
                  ),
                ],
              ),
            ],
          ),

        // 4. Level Complete Screen Overlay (with confetti, stars, rainbow text)
        if (controller.state == GameState.levelComplete)
          _buildScreenOverlay(
            context: context,
            isLevelComplete: true,
            title: controller.translate('level_complete'),
            titleColor: GameConstants.neonGreen,
            score: controller.score,
            content: [
              AnimatedStars(count: starsCount),
              const SizedBox(height: 24.0),
              if (controller.currentLevelNumber < 5)
                PulsingButton(
                  onPressed: () => controller.startLevel(controller.currentLevelNumber + 1),
                  child: _buildNeonButtonRaw(
                    text: controller.translate('next_level'),
                    color: GameConstants.neonGreen,
                  ),
                )
              else
                Column(
                  children: [
                    Text(
                      controller.translate('all_cleared'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 15.0),
                  ],
                ),
              const SizedBox(height: 15.0),
              _buildNeonButton(
                text: controller.translate('main_menu'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                color: Colors.white60,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildScreenOverlay({
    required BuildContext context,
    required String title,
    required Color titleColor,
    bool isGameOver = false,
    bool isLevelComplete = false,
    int? score,
    required List<Widget> content,
  }) {
    return Container(
      color: Colors.black.withOpacity(0.65), // Soft dark vignette backdrop
      child: Center(
        child: Container(
          width: 310,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          decoration: BoxDecoration(
            color: GameConstants.cardBg,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: const Color(0xFF2E2E42),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20.0,
                offset: const Offset(0.0, 8.0),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGameOver)
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                )
              else if (isLevelComplete)
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                )
              else
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              const SizedBox(height: 12.0),
              if (score != null) ...[
                Text(
                  Provider.of<GameController>(context, listen: false).translate('final_score'),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4.0),
                CounterText(
                  target: score,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 24.0),
              ...content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeonButtonRaw({
    required String text,
    required Color color,
  }) {
    bool isPrimary = color != Colors.white60;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: isPrimary ? color : const Color(0xFF2C2C3E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14.0),
        border: isPrimary ? null : Border.all(color: Colors.white12, width: 1.0),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 8.0,
            offset: const Offset(0.0, 3.0),
          )
        ] : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : Colors.white70,
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildNeonButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: _buildNeonButtonRaw(text: text, color: color),
    );
  }
}

// ---------------------------------------------
// Custom Animation Widgets for Juiciness
// ---------------------------------------------

class ScoreText extends StatefulWidget {
  final int score;
  const ScoreText({Key? key, required this.score}) : super(key: key);

  @override
  _ScoreTextState createState() => _ScoreTextState();
}

class _ScoreTextState extends State<ScoreText> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<Map<String, dynamic>> _floatingPoints = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant ScoreText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller.forward(from: 0.0);
      int diff = widget.score - oldWidget.score;
      if (diff > 0) {
        _spawnFloatingPoints(diff);
      }
    }
  }

  void _spawnFloatingPoints(int diff) {
    final Map<String, dynamic> item = {
      'id': DateTime.now().microsecondsSinceEpoch,
      'text': '+$diff',
      'controller': AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    };
    
    final animController = item['controller'] as AnimationController;
    animController.forward().then((_) {
      if (mounted) {
        setState(() {
          _floatingPoints.removeWhere((x) => x['id'] == item['id']);
        });
      }
      animController.dispose();
    });

    setState(() {
      _floatingPoints.add(item);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var item in _floatingPoints) {
      (item['controller'] as AnimationController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        ScaleTransition(
          scale: _animation,
          child: Text(
            "${Provider.of<GameController>(context).translate('score')}: ${widget.score}",
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ..._floatingPoints.map((item) {
          final anim = item['controller'] as AnimationController;
          return AnimatedBuilder(
            animation: anim,
            builder: (context, child) {
              double opacity = (1.0 - anim.value).clamp(0.0, 1.0);
              double yOffset = -15.0 - (anim.value * 35.0);
              return Positioned(
                right: 0.0,
                top: yOffset,
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    item['text'] as String,
                    style: TextStyle(
                      color: (item['text'] as String).contains('100')
                          ? GameConstants.neonYellow
                          : Colors.white70,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class CounterText extends StatefulWidget {
  final int target;
  final TextStyle style;
  const CounterText({Key? key, required this.target, required this.style}) : super(key: key);

  @override
  _CounterTextState createState() => _CounterTextState();
}

class _CounterTextState extends State<CounterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.target.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toInt().toString(),
          style: widget.style,
        );
      },
    );
  }
}

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const GlitchText({Key? key, required this.text, required this.style}) : super(key: key);

  @override
  _GlitchTextState createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bool showGlitch = _random.nextDouble() < 0.15;
        final double offsetX = showGlitch ? (_random.nextDouble() * 6.0 - 3.0) : 0.0;
        final double offsetY = showGlitch ? (_random.nextDouble() * 2.0 - 1.0) : 0.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (showGlitch)
              Positioned(
                left: offsetX - 2,
                top: offsetY,
                child: Text(
                  widget.text,
                  style: widget.style.copyWith(color: Colors.cyanAccent.withOpacity(0.85)),
                ),
              ),
            if (showGlitch)
              Positioned(
                left: -offsetX + 2,
                top: -offsetY,
                child: Text(
                  widget.text,
                  style: widget.style.copyWith(color: Colors.redAccent.withOpacity(0.85)),
                ),
              ),
            Text(
              widget.text,
              style: widget.style,
            ),
          ],
        );
      },
    );
  }
}

class RainbowShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const RainbowShimmerText({Key? key, required this.text, required this.style}) : super(key: key);

  @override
  _RainbowShimmerTextState createState() => _RainbowShimmerTextState();
}

class _RainbowShimmerTextState extends State<RainbowShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFFF2E93), // Pink
                Color(0xFFB026FF), // Purple
                Color(0xFF007BFF), // Blue
                Color(0xFF00FFFF), // Cyan
                Color(0xFF00FF66), // Green
                Color(0xFFFFD300), // Yellow
                Color(0xFFFF2E93), // Loop back
              ],
              stops: [
                0.0,
                (0.16 + _controller.value * 0.84).clamp(0.0, 1.0),
                (0.33 + _controller.value * 0.67).clamp(0.0, 1.0),
                (0.5 + _controller.value * 0.5).clamp(0.0, 1.0),
                (0.66 + _controller.value * 0.34).clamp(0.0, 1.0),
                (0.83 + _controller.value * 0.17).clamp(0.0, 1.0),
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: widget.style.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

class AnimatedStars extends StatefulWidget {
  final int count;
  const AnimatedStars({Key? key, required this.count}) : super(key: key);

  @override
  _AnimatedStarsState createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<AnimatedStars> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.bounceOut),
      );
    }).toList();

    _animateStars();
  }

  void _animateStars() async {
    for (int i = 0; i < widget.count; i++) {
      await Future.delayed(Duration(milliseconds: 350 * i));
      if (mounted) _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isGold = index < widget.count;
        return ScaleTransition(
          scale: _animations[index],
          child: Icon(
            Icons.star_rounded,
            color: isGold ? Colors.amberAccent : Colors.white12,
            size: 46.0,
            shadows: isGold
                ? [
                    Shadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 10.0,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class PulsingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const PulsingButton({Key? key, required this.child, required this.onPressed}) : super(key: key);

  @override
  _PulsingButtonState createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: widget.child,
      ),
    );
  }
}
