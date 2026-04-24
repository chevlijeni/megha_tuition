import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF194464);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color navBackground = Color(0xFFF1F5F9); // Light integrated blue for Bottom Nav
  static const Color headerBlue = Color(0xFF194464);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF1A324D)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, accentBlue],
  );

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static LinearGradient getBackgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark 
        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
        : [primaryBlue, const Color(0xFF1A324D)],
    );
  }

  static BoxDecoration headerDecorationWithMode(bool isDark) => BoxDecoration(
    gradient: getBackgroundGradient(isDark),
    boxShadow: const [
      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
    ],
  );

  static BoxDecoration get headerDecoration => headerDecorationWithMode(ThemeManager.instance.isDarkMode);

  static ThemeData get lightTheme {
    // ... logic remains same, but using flexible values
    return _buildTheme(false);
  }

  static ThemeData get darkTheme {
    return _buildTheme(true);
  }

  static ThemeData _buildTheme(bool isDark) {
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final surfaceColor = isDark ? surfaceDark : surfaceWhite;
    final primaryTxt = isDark ? textPrimaryDark : textPrimary;
    final secondaryTxt = isDark ? textSecondaryDark : textSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceColor,
        background: bgColor,
        error: errorRed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(color: primaryTxt, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: GoogleFonts.outfit(color: primaryTxt, fontWeight: FontWeight.bold, fontSize: 26),
        titleLarge: GoogleFonts.outfit(color: primaryTxt, fontWeight: FontWeight.w600, fontSize: 20),
        bodyLarge: GoogleFonts.outfit(color: primaryTxt, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: secondaryTxt, fontSize: 14),
      ),
    );
  }
}

class ThemeManager with ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
