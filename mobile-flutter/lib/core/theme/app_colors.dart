import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds (Deep Space Obsidian & Dark Slate)
  static const Color obsidianBlack = Color(0xFF0A0E14);
  static const Color darkSlate = Color(0xFF121721);
  static const Color darkCard = Color(0xFF121721);
  static const Color darkCardElevated = Color(0xFF181F2C);
  
  // Luxury Champagne Gold (Exact match to Web Champagne Gold #D4AF37)
  static const Color champagneGold = Color(0xFFD4AF37);    // Primary luxury accent (active tabs, logo dot, badges)
  static const Color goldLight = Color(0xFFF3E5AB);        // Soft Champagne Ivory
  static const Color goldDark = Color(0xFFAA7C11);         // Deep Bronzed Gold
  static const Color deepGold = Color(0xFFAA7C11);
  static const Color prestigeGold = Color(0xFFD4AF37);     // Selective Gold (Verified Badge, Trust Score, AI Coach)

  // Velvet Rose Accents & Glows (Exact match to Web #E27D8D and rose-glow-btn)
  static const Color primaryRose = Color(0xFFE27D8D);      // Signature Velvet Rose
  static const Color roseGlow = Color(0xFFE27D8D);
  static const Color violetAccent = Color(0xFF8C52FF);     // Signature Royal Violet
  static const Color royalPurple = Color(0xFF2D1B4E);      // Deep Royal Purple / Wine

  // Verified & Trust Emerald
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color emeraldSuccess = Color(0xFF10B981);
  
  // Borders & Glows
  static const Color borderSubtle = Color(0x1AFFFFFF);     // 10% white for crisp glass borders
  static const Color borderGold = Color(0x4DD4AF37);       // 30% gold border
  static const Color borderGoldStrong = Color(0x80D4AF37); // 50% gold border
  static const Color borderGlass = Color(0x1AFFFFFF);      // 10% white
  static const Color glassBorder = Color(0x1AFFFFFF);      // 10% white
  
  // High-Contrast Typography
  static const Color textPure = Color(0xFFFFFFFF);
  static const Color textOffWhite = Color(0xFFF5F5F1);     // Soft Off-White
  static const Color textMuted = Color(0xFF94A3B8);        // Muted Slate Grey
  static const Color textSecondary = Color(0xFF94A3B8);    // Cool Slate Blue / Grey
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textGold = Color(0xFFD4AF37);         // Gold text

  // Signature Buttons Gradients
  // 1. Luxury Gold Gradient (The exact gradient from Web & Welcome Screen)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB), Color(0xFFAA7C11)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 2. Velvet Rose Glow CTA Gradient (The signature rose-glow-btn from Web, Welcome, & Auth screens)
  static const LinearGradient roseGlowGradient = LinearGradient(
    colors: [Color(0xFFE27D8D), Color(0xFF2D1B4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFE27D8D), Color(0xFF2D1B4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 3. Connect Gradient (From React App)
  static const LinearGradient connectGradient = LinearGradient(
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
