import 'package:flutter/material.dart';

class GameConstants {
  // Logical coordinate system size
  static const double logicalWidth = 400.0;
  static const double logicalHeight = 700.0;

  // Ball dimensions
  static const double ballRadius = 15.0;
  static const double ballDiameter = ballRadius * 2;

  // Color Palette (Minimalist Matte Premium)
  static const Color obsidianBg = Color(0xFF12121F); // Warm deep dark charcoal
  static const Color cardBg = Color(0xFF1A1A2E);     // Dark matte card fill
  static const Color neonText = Color(0xFFE9C46A);   // Warm amber highlight
  
  static const Color neonRed = Color(0xFFE56B6F);    // Warm Coral / Deep Red
  static const Color neonBlue = Color(0xFF355C7D);   // Slate/Ocean Blue
  static const Color neonGreen = Color(0xFF2E6F40);  // Forest Green
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

  static Color getLevelColor(int index) {
    return levelColors[index % levelColors.length];
  }
}
