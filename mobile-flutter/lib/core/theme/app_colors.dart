import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds
  static const Color obsidianBlack = Color(0xFF0B0E14);
  static const Color darkSlate = Color(0xFF121721);
  static const Color darkCard = Color(0xFF171E2D);
  static const Color darkCardElevated = Color(0xFF1E273A);
  
  // Romantic Matrimonial Accents (Velvet Rose & Crimson, replacing shouting gold/yellow)
  static const Color champagneGold = Color(0xFFE11D48); // Velvet Rose
  static const Color goldLight = Color(0xFFFB7185);     // Soft Rose Blush
  static const Color goldDark = Color(0xFFBE123C);      // Deep Crimson
  static const Color deepGold = Color(0xFFBE123C);
  static const Color roseGlow = Color(0xFFE11D48);
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color royalPurple = Color(0xFF2D1B4E);
  
  // Borders & Glows
  static const Color borderSubtle = Color(0xFF232D3F);
  static const Color borderGold = Color(0x33E11D48); // 20% rose glow
  static const Color borderGoldStrong = Color(0x66E11D48); // 40% rose glow
  static const Color borderGlass = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  
  // Text Colors
  static const Color textPure = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textGold = Color(0xFFFB7185); // Soft Rose text

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFFBE123C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFBE123C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF161D2B), Color(0xFF0F141E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient scannerGlowGradient = LinearGradient(
    colors: [
      Color(0x00E11D48),
      Color(0x80E11D48),
      Color(0xFFE11D48),
      Color(0x80E11D48),
      Color(0x00E11D48),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
