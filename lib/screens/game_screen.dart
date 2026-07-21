import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';
import '../utils/constants.dart';
import '../widgets/game_painter.dart';
import '../widgets/hud_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start game on boot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameController>(context, listen: false).startGame();
    });
  }

  @override
  void deactivate() {
    // Proactively pause the game loop when navigating away
    Provider.of<GameController>(context, listen: false).pauseGame();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context, listen: false);

    return Scaffold(
      backgroundColor: GameConstants.obsidianBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate uniform scaling factor to fit the logical canvas inside any aspect ratio
          final double scale = min(
            constraints.maxWidth / GameConstants.logicalWidth,
            constraints.maxHeight / GameConstants.logicalHeight,
          );

          final double canvasWidth = GameConstants.logicalWidth * scale;
          final double canvasHeight = GameConstants.logicalHeight * scale;

          // Centering offsets
          final double offsetX = (constraints.maxWidth - canvasWidth) / 2;
          final double offsetY = (constraints.maxHeight - canvasHeight) / 2;

          return Stack(
            children: [
              // Theme Background Image
              Positioned.fill(
                child: Consumer<GameController>(
                  builder: (context, c, child) {
                    return Image.asset(
                      "assets/images/themes/${c.currentTheme}.png",
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Interactive Canvas area (centered)
              Positioned(
                left: offsetX,
                top: offsetY,
                width: canvasWidth,
                height: canvasHeight,
                child: GestureDetector(
                  onTapDown: (details) {
                    // Convert physical tap coordinates to logical game coordinates
                    final Offset localPos = details.localPosition;
                    final Offset logicalTapPos = Offset(
                      localPos.dx / scale,
                      localPos.dy / scale,
                    );
                    controller.handleTap(logicalTapPos);
                  },
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: controller.tickNotifier,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(canvasWidth, canvasHeight),
                          painter: GamePainter(controller: controller),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // HUD & Overlay Menu Layers (full screen dimensions)
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: false, // Make overlays clickable
                  child: HudWidget(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
