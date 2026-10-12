import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds
  static const Color obsidianBlack = Color(0xFF0B0E14);
  static const Color darkSlate = Color(0xFF121721);
  static const Color darkCard = Color(0xFF171E2D);
  static const Color darkCardElevated = Color(0xFF1E273A);
  
  // Luxury Accents
  static const Color champagneGold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF5DE88);
  static const Color goldDark = Color(0xFFAA820A);
  static const Color roseGlow = Color(0xFFE11D48);
  static const Color emeraldVerified = Color(0xFF10B981);
  
  // Borders & Glows
  static const Color borderSubtle = Color(0xFF232D3F);
  static const Color borderGold = Color(0x33D4AF37); // 20% opacity
  static const Color borderGoldStrong = Color(0x66D4AF37); // 40% opacity
  static const Color borderGlass = Color(0x1AFFFFFF); // 10% white
  
  // Text Colors
  static const Color textPure = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textGold = Color(0xFFD4AF37);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5C058), Color(0xFFD4AF37), Color(0xFFAA820A)],
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
      Color(0x00D4AF37),
      Color(0x80D4AF37),
      Color(0xFFD4AF37),
      Color(0x80D4AF37),
      Color(0x00D4AF37),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
