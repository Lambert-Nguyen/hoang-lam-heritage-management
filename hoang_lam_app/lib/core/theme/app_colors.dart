import 'package:flutter/material.dart';

/// App color palette following WCAG AA compliant contrast ratios
/// Designed for accessibility (older users - Mom 50s+)
class AppColors {
  AppColors._();

  // Primary Colors - Hotel Brand
  static const Color primary = Color(0xFF1565C0); // Blue
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondary = Color(0xFF26A69A); // Teal
  static const Color secondaryLight = Color(0xFF64D8CB);
  static const Color secondaryDark = Color(0xFF00766C);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Room Status Colors (distinguishable)
  static const Color available = Color(0xFF2E7D32); // Green
  static const Color occupied = Color(0xFFC62828); // Red
  static const Color cleaning = Color(0xFFF9A825); // Amber
  static const Color maintenance = Color(0xFF9E9E9E); // Gray
  static const Color blocked = Color(0xFF795548); // Brown

  // Financial Colors
  static const Color income = Color(0xFF2E7D32); // Green
  static const Color expense = Color(0xFFC62828); // Red
  static const Color profit = Color(0xFF1565C0); // Blue

  // Text Colors (high contrast for readability)
  static const Color textPrimary = Color(0xFF212121); // Dark gray
  static const Color textSecondary = Color(0xFF616161); // Medium gray
  static const Color textHint = Color(0xFF9E9E9E); // Light gray
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE0E0E0);
  static const Color card = Color(0xFFFFFFFF);

  // Error/Warning/Success States
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBackground = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningBackground = Color(0xFFFFF3E0);
  static const Color success = Color(0xFF388E3C);
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF1976D2);
  static const Color infoBackground = Color(0xFFE3F2FD);

  // Divider & Border
  static const Color divider = Color(0xFFBDBDBD);
  static const Color border = Color(0xFFE0E0E0);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Room Status Colors (aliases for backwards compatibility)
  static const Color roomOccupied = occupied;
  static const Color roomAvailable = available;
  static const Color roomCleaning = cleaning;
  static const Color roomMaintenance = maintenance;

  // Offline Banner
  static const Color offline = Color(0xFFFF9800);
  static const Color onOffline = Color(0xFFFFFFFF);

  // ==================== Dark Mode Colors ====================
  
  // Dark Background Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkCard = Color(0xFF242424);

  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFE1E1E1);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextHint = Color(0xFF757575);

  // Dark Divider & Border
  static const Color darkDivider = Color(0xFF424242);
  static const Color darkBorder = Color(0xFF383838);
}
