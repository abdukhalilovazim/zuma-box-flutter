import 'package:flutter/material.dart';
import '../../game/game_controller.dart';
import 'package:provider/provider.dart';
import '../../theme/background_painters.dart';

class DynamicBackground extends StatefulWidget {
  final Widget child;

  const DynamicBackground({super.key, required this.child});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // Use a very slow animation duration for calm parallax motion
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  CustomPainter _getPainterForTheme(String themeKey, double animValue) {
    switch (themeKey) {
      case 'germany':
        return GermanyPainter(animValue);
      case 'egypt':
        return EgyptPainter(animValue);
      case 'elephant':
        return ElephantPainter(animValue);
      case 'tokyo':
      default:
        return TokyoPainter(animValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.select<GameController, String>((c) => c.currentTheme);

    return Stack(
      children: [
        // The Parallax Background layer
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: CustomPaint(
                  key: ValueKey<String>(theme),
                  painter: _getPainterForTheme(theme, _bgController.value),
                  child: Container(),
                ),
              );
            },
          ),
        ),
        // The foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
