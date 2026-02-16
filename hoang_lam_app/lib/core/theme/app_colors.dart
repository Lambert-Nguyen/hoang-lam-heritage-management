import 'package:flutter/material.dart';

/// App color palette following WCAG AA compliant contrast ratios
/// Heritage-themed colors for Hoàng Lâm Heritage Suites
/// Designed for accessibility (older users - Mom 50s+)
class AppColors {
  AppColors._();

  // ==================== Heritage Color Palette ====================
  
  // Primary (Dark Heritage Green) - Main brand color
  static const Color primary = Color(0xFF254634);
  static const Color primaryLight = Color(0xFF3D6B52);
  static const Color primaryDark = Color(0xFF17291E);
  static const Color onPrimary = Color(0xFFF5EEE0); // Warm cream text on primary

  // Secondary / Accent (Gold) - CTA highlights, links
  static const Color secondary = Color(0xFF9F8033);
  static const Color secondaryLight = Color(0xFFC4A04A);
  static const Color secondaryDark = Color(0xFF7A6227);
  static const Color onSecondary = Color(0xFFF5EEE0);

  // Deep Accent (Near-black Green) - Body text on light backgrounds
  static const Color deepAccent = Color(0xFF17291E);
  
  // Muted Accent (Sage Gray-Green) - Secondary text, dividers
  static const Color mutedAccent = Color(0xFFA2A698);
  
  // Soft Surface (Sand) - Cards, elevated surfaces
  static const Color sand = Color(0xFFD1C9B0);
  
  // Background (Warm Cream) - App background
  static const Color cream = Color(0xFFF5EEE0);

  // ==================== UI Role Mappings ====================
  
  // Room Status Colors (distinguishable)
  static const Color available = Color(0xFF254634); // Heritage green
  static const Color occupied = Color(0xFFC62828); // Red
  static const Color cleaning = Color(0xFF9F8033); // Gold accent
  static const Color maintenance = Color(0xFFA2A698); // Sage gray
  static const Color blocked = Color(0xFF17291E); // Deep accent

  // Financial Colors
  static const Color income = Color(0xFF2E7D32); // Green for positive
  static const Color expense = Color(0xFFC62828); // Red for negative
  static const Color profit = Color(0xFF254634); // Primary green

  // Text Colors (high contrast for readability)
  static const Color textPrimary = Color(0xFF17291E); // Deep accent - body text
  static const Color textSecondary = Color(0xFFA2A698); // Muted accent
  static const Color textHint = Color(0xFFA2A698); // Muted accent
  static const Color textOnDark = Color(0xFFF5EEE0); // Cream on dark

  // Background Colors
  static const Color background = Color(0xFFF5EEE0); // Warm cream
  static const Color surface = Color(0xFFF5EEE0); // Cream
  static const Color surfaceVariant = Color(0xFFD1C9B0); // Sand
  static const Color card = Color(0xFFD1C9B0); // Sand for cards

  // Error/Warning/Success States
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBackground = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningBackground = Color(0xFFFFF3E0);
  static const Color success = Color(0xFF388E3C);
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF254634); // Primary green
  static const Color infoBackground = Color(0xFFD1C9B0); // Sand

  // Status Indicator Colors (for badges, chips, category indicators)
  static const Color statusBlue = Color(0xFF2196F3);       // Confirmed, info items
  static const Color statusPurple = Color(0xFF9C27B0);     // Website source, special items
  static const Color statusBrown = Color(0xFF795548);       // Snack, other categories
  static const Color statusTeal = Color(0xFF009688);        // Teal category items
  static const Color statusDeepOrange = Color(0xFFFF5722);  // Urgent notifications
  static const Color statusAmber = Color(0xFFFFC107);        // Beer, highlight warnings
  static const Color statusAmberLight = Color(0xFFFFF8E1);  // Amber background (50)
  static const Color statusAmberBorder = Color(0xFFFFE082); // Amber border (200)
  static const Color statusAmberDark = Color(0xFFF57F17);   // Amber text (900)
  static const Color statusAmberIcon = Color(0xFFFFA000);   // Amber icon (700)
  static const Color statusCyan = Color(0xFF00BCD4);         // Water, coolant items
  static const Color statusBlueGrey = Color(0xFF607D8B);    // Neutral/inactive items

  // Brand Colors (external platform brand identity - do not change)
  static const Color brandBookingCom = Color(0xFF003580);
  static const Color brandAgoda = Color(0xFFEC1C24);
  static const Color brandAirbnb = Color(0xFFFF5A5F);
  static const Color brandZalo = Color(0xFF0068FF);
  static const Color brandTraveloka = Color(0xFF2D90ED);

  // Divider & Border
  static const Color divider = Color(0xFFA2A698); // Muted accent
  static const Color border = Color(0xFFD1C9B0); // Sand

  // Shadow
  static const Color shadow = Color(0x1A17291E); // Based on deep accent

  // Room Status Colors (aliases for backwards compatibility)
  static const Color roomOccupied = occupied;
  static const Color roomAvailable = available;
  static const Color roomCleaning = cleaning;
  static const Color roomMaintenance = maintenance;

  // Offline Banner
  static const Color offline = Color(0xFF9F8033); // Gold accent
  static const Color onOffline = Color(0xFFF5EEE0);

  // ==================== Dark Mode Colors ====================
  
  // Dark Background Colors
  static const Color darkBackground = Color(0xFF17291E); // Deep accent
  static const Color darkSurface = Color(0xFF1E3328);
  static const Color darkSurfaceVariant = Color(0xFF254634); // Primary
  static const Color darkCard = Color(0xFF1E3328);

  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFF5EEE0); // Cream
  static const Color darkTextSecondary = Color(0xFFD1C9B0); // Sand
  static const Color darkTextHint = Color(0xFFA2A698); // Muted accent

  // Dark Divider & Border
  static const Color darkDivider = Color(0xFF3D6B52);
  static const Color darkBorder = Color(0xFF254634);
}
