import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds (Deep Space Obsidian & Dark Slate from React)
  static const Color obsidianBlack = Color(0xFF0A0E14);
  static const Color darkSlate = Color(0xFF10141C);
  static const Color darkCard = Color(0xFF161D2B);
  static const Color darkCardElevated = Color(0xFF1E273A);
  
  // React Brand Accents (Exact match to React Colors.primary #E27D8D)
  static const Color primaryRose = Color(0xFFE27D8D);      // Signature React Rose Pink
  static const Color violetAccent = Color(0xFF8C52FF);     // Signature React Royal Violet
  static const Color champagneGold = Color(0xFFE27D8D);    // Primary feature accent (active tabs, logo dot, badges)
  static const Color goldLight = Color(0xFFF3A6B2);        // Soft Rose Blush
  static const Color goldDark = Color(0xFF8C52FF);         // Royal Violet
  static const Color deepGold = Color(0xFF8C52FF);
  static const Color roseGlow = Color(0xFFE27D8D);
  static const Color prestigeGold = Color(0xFFD4AF37);     // Selective Gold (Verified Badge, Trust Score, AI Coach)
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color royalPurple = Color(0xFF2D1B4E);
  
  // Borders & Glows
  static const Color borderSubtle = Color(0xFF232D3F);
  static const Color borderGold = Color(0x4DE27D8D);       // 30% rose border
  static const Color borderGoldStrong = Color(0x80E27D8D); // 50% rose border
  static const Color borderGlass = Color(0x1AFFFFFF);      // 10% white
  static const Color glassBorder = Color(0x1AFFFFFF);      // 10% white
  
  // High-Contrast Typography
  static const Color textPure = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textGold = Color(0xFFE27D8D);         // Rose accent text

  // Signature React Gradient: Rose Pink to Royal Violet (The exact Connect button gradient!)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE27D8D), Color(0xFF8C52FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFE27D8D), Color(0xFF8C52FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF161D2B), Color(0xFF0F141E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Paywall Gradient (Royal Violet into Soft Rose)
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF4C1D95), Color(0xFFE27D8D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerGlowGradient = LinearGradient(
    colors: [
      Color(0x00E27D8D),
      Color(0x80E27D8D),
      Color(0xFFE27D8D),
      Color(0x80E27D8D),
      Color(0x00E27D8D),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
