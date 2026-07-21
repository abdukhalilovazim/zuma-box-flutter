import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_controller.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import '../widgets/common/dynamic_background.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/glass_button.dart';

enum MenuState { home, levels, settings }

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _bgController;
  MenuState _menuState = MenuState.home;

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
      body: DynamicBackground(
        child: Stack(
          children: [

          // Top Right Controls (Settings or Back)
          Positioned(
            top: 20.0,
            right: 20.0,
            left: 20.0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_menuState != MenuState.home)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _menuState = MenuState.home;
                        });
                      },
                      child:                        GlassCard(
                          borderRadius: 30.0,
                          padding: const EdgeInsets.all(10.0),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                        ),
                    )
                  else
                    const SizedBox(),

                  if (_menuState == MenuState.home)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _menuState = MenuState.settings;
                        });
                      },
                      child: GlassCard(
                        borderRadius: 30.0,
                        padding: const EdgeInsets.all(10.0),
                        child: const Icon(Icons.settings_rounded, color: Colors.white70, size: 24),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Menu Content
          SafeArea(
            child: Column(
              children: [

                if (_menuState == MenuState.home) ...[
                  const Spacer(flex: 2),

                  // Flat Minimal Logo
                  Column(
                    children: [
                      Text(
                        "ZUMA",
                        style: TextStyle(
                          fontSize: 66.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8.0,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "BOX",
                        style: TextStyle(
                          fontSize: 38.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6.0,
                          color: GameConstants.neonText.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24.0),

                  // Best Score Banner
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    borderRadius: 20.0,
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

                  // Start Game Button
                  GlassButton(
                    onTap: () {
                      setState(() {
                        _menuState = MenuState.levels;
                      });
                    },
                    padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 48.0),
                    child: Text(
                      controller.translate("start_game"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),
                ] else if (_menuState == MenuState.settings) ...[
                  // Settings View
                  const Spacer(flex: 1),
                  Text(
                    controller.translate('select_theme'),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    height: 120.0,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildThemeCard(context, controller, "tokyo", "tokyo.png"),
                        _buildThemeCard(context, controller, "germany", "germany.png"),
                        _buildThemeCard(context, controller, "egypt", "egypt.png"),
                        _buildThemeCard(context, controller, "elephant", "elephant.png"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  Text(
                    "LANGUAGE",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    borderRadius: 20.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ["UZ", "RU", "EN"].map((lang) {
                        final isSelected = controller.currentLanguage == lang.toLowerCase();
                        return GestureDetector(
                          onTap: () {
                            controller.setLanguage(lang.toLowerCase());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Text(
                              lang,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Spacer(flex: 3),
                ] else if (_menuState == MenuState.levels) ...[
                  // Level Select Section
                  const Spacer(flex: 1),
                  Text(
                    "ZUMA BOX",
                    style: TextStyle(
                      color: Colors.white12,
                      fontSize: 32.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    controller.translate('select_level'),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Level Grid
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(overscroll: false),
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 30,
                          itemBuilder: (context, index) {
                            final levelNum = index + 1;
                            final isUnlocked = unlockedLevels.contains(levelNum);
                            final levelColor = GameConstants.getLevelColor(index % 5, theme: controller.currentTheme);

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
                                  GlassCard(
                                    borderRadius: 15.0,
                                    borderColor: isCompleted
                                            ? GameConstants.neonGreen.withValues(alpha: 0.85)
                                            : (isUnlocked
                                                ? const Color(0xFF2C2C3E)
                                                : Colors.white10),
                                    borderWidth: isCompleted ? 2.0 : 1.5,
                                    color: isUnlocked ? GameConstants.cardBg.withValues(alpha: 0.4) : Colors.black38,
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
                  ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, GameController controller, String themeKey, String fileName) {
    final isSelected = controller.currentTheme == themeKey;
    final themeName = controller.translate(themeKey);

    return GestureDetector(
      onTap: () {
        controller.setTheme(themeKey);
      },
      child: GlassCard(
        width: 140.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        borderRadius: 16.0,
        borderColor: isSelected ? Colors.white : Colors.white12,
        borderWidth: isSelected ? 2.0 : 1.0,
        padding: const EdgeInsets.all(0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/images/themes/$fileName",
              fit: BoxFit.cover,
              colorBlendMode: isSelected ? null : BlendMode.darken,
              color: isSelected ? null : Colors.black.withValues(alpha: 0.5),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  themeName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

