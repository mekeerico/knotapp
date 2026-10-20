import 'package:flutter/material.dart';

class AppColors {
  // Brand Backgrounds
  static const Color obsidianBlack = Color(0xFF0B0E14);
  static const Color darkSlate = Color(0xFF121721);
  static const Color darkCard = Color(0xFF161D2B);
  static const Color darkCardElevated = Color(0xFF1E273A);
  
  // Lively Radiant Accents (High-Contrast, Zero Dullness, No Shouting Yellow)
  static const Color champagneGold = Color(0xFFFF3366); // Radiant Coral-Rose (Primary Accent)
  static const Color goldLight = Color(0xFFFF7A95);     // Bright Soft Coral Blush
  static const Color goldDark = Color(0xFFE11D48);      // Vivid Deep Rose
  static const Color deepGold = Color(0xFFE11D48);
  static const Color roseGlow = Color(0xFFFF3366);
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color royalPurple = Color(0xFF2D1B4E);
  
  // Borders & Glows (Crisp, High-Luminance Definition)
  static const Color borderSubtle = Color(0xFF232D3F);
  static const Color borderGold = Color(0x66FF3366); // 40% radiant coral border (clearly defined!)
  static const Color borderGoldStrong = Color(0x99FF3366); // 60% radiant coral border
  static const Color borderGlass = Color(0x26FFFFFF); // 15% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white
  
  // High-Contrast Text Colors (Crisp White & Bright Pearl - Never muddy or dark)
  static const Color textPure = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFCBD5E1); // Bright silver-pearl (high readability)
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textSubtle = Color(0xFF94A3B8); // Clear readable subtitle
  static const Color textGold = Color(0xFFFF5A79); // Radiant lively accent text

  // Lively Radiant Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFF5A79), Color(0xFFFF3366), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFFF5A79), Color(0xFFFF3366), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF18202E), Color(0xFF0F141E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient scannerGlowGradient = LinearGradient(
    colors: [
      Color(0x00FF3366),
      Color(0x80FF3366),
      Color(0xFFFF3366),
      Color(0x80FF3366),
      Color(0x00FF3366),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
