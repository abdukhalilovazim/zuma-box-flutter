import 'package:flutter/material.dart';

class GameConstants {
  // Logical coordinate system size
  static const double logicalWidth = 400.0;
  static const double logicalHeight = 700.0;

  // Ball dimensions
  static const double ballRadius = 19.0;
  static const double ballDiameter = ballRadius * 2;

  // Color Palette (Minimalist Matte Premium)
  static const Color obsidianBg = Color(0xFF12121F); // Warm deep dark charcoal
  static const Color cardBg = Color(0xFF1A1A2E); // Dark matte card fill
  static const Color neonText = Color(0xFFE9C46A); // Warm amber highlight

  static const Color neonRed = Color(0xFFE56B6F); // Warm Coral / Deep Red
  static const Color neonBlue = Color(0xFF355C7D); // Slate/Ocean Blue
  static const Color neonGreen = Color(0xFF2E6F40); // Forest Green
  static const Color neonYellow = Color(0xFFE9C46A); // Soft Gold / Warm Amber
  static const Color neonPurple = Color(0xFF8F7197); // Dusty Purple
  static const Color neonOrange = Color(0xFF5C9EAD); // Slate Cyan

  static const List<Color> levelColors = [
    neonRed,
    neonBlue,
    neonGreen,
    neonYellow,
    neonPurple,
    neonOrange,
  ];

  static const Map<String, List<Color>> themePalettes = {
    "tokyo": levelColors, // Original neon colors
    "germany": [
      Color(0xFFE63946),
      Color(0xFF1D3557),
      Color(0xFFF1FAEE),
      Color(0xFFA8DADC),
      Color(0xFF457B9D),
    ], // Distinct vibrant colors
    "egypt": [
      Color(0xFFEEDD82),
      Color(0xFF008080),
      Color(0xFFC19A6B),
      Color(0xFF800000),
      Color(0xFFD2B48C),
    ], // Desert, gold, teal
    "elephant": [
      Color(0xFF8A9A5B),
      Color(0xFF556B2F),
      Color(0xFF708090),
      Color(0xFF8B4513),
      Color(0xFF2F4F4F),
    ], // Jungle, grey, brown
  };

  static Color getLevelColor(int index, {String theme = "tokyo"}) {
    final palette = themePalettes[theme] ?? levelColors;
    return palette[index % palette.length];
  }
}
