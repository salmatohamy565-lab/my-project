import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds - Clean, premium white and soft off-whites
  static const Color bgStart = Color(0xFFFFFFFF);
  static const Color bgMiddle = Color(0xFFF8F9FA);
  static const Color bgEnd = Color(0xFFE9ECEF);

  // Gradient lists
  static const List<Color> bgGradient = [bgStart, bgMiddle, bgEnd];

  // Specific component backgrounds - light theme
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color loginCardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF1F3F5);
  static const Color globalLogoBarBg = Color(0xFFFFFFFF);

  // Typography - high contrast dark tones
  static const Color textMain = Color(0xFF0A0A0A);     // #0A0A0A (Black)
  static const Color textDefault = Color(0xFF2B2D31);  // #2B2D31 (Dark Grey)
  static const Color textMuted = Color(0xFF5C6066);    // #5C6066 (Medium Grey)
  static const Color textDark = Color(0xFF0A0A0A);

  // Borders - clean grey lines
  static const Color borderDark = Color(0xFFCED4DA);
  static const Color borderLight = Color(0xFFE9ECEF);  // #E9ECEF
  static const Color borderMedium = Color(0xFFDEE2E6);

  // Primary Accent (Black/Charcoal)
  static const Color primaryAccent = Color(0xFF0A0A0A);
  
  // Secondary Accent (Medium/Light Grey)
  static const Color secondaryAccent = Color(0xFF5C6066);

  // Accent Gradients
  static const List<Color> primaryGradient = [primaryAccent, Color(0xFF2B2D31)];
  
  // Success / Done (Green)
  static const Color successStart = Color(0xFF2B8A3E);
  static const Color successEnd = Color(0xFF40C057);
  static const List<Color> successGradient = [successStart, successEnd];
  static const List<Color> badgeDoneGradient = [Color(0xFF2B8A3E), Color(0xFF37B24D)];

  // Warning / Pending (Amber)
  static const Color warningStart = Color(0xFFE67E22);
  static const Color warningEnd = Color(0xFFF39C12);
  static const List<Color> warningGradient = [warningStart, warningEnd];

  // Danger / Error / Delete / Logout (Red/Orange)
  static const Color dangerStart = Color(0xFFC92A2A);
  static const Color dangerEnd = Color(0xFFFA5252);
  static const List<Color> dangerGradient = [dangerStart, dangerEnd];
  static const List<Color> deleteGradient = [Color(0xFFE03131), Color(0xFFFA5252)];
}

