import 'package:flutter/material.dart';

/// App spacing constants for consistent layouts
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (4dp)
  static const double unit = 4.0;

  // Standard spacing values
  static const double xs = 4.0; // Extra small
  static const double sm = 8.0; // Small
  static const double md = 16.0; // Medium
  static const double lg = 24.0; // Large
  static const double xl = 32.0; // Extra large
  static const double xxl = 48.0; // Extra extra large

  // Screen padding
  static const double screenPadding = 16.0;
  static const double screenPaddingLarge = 24.0;

  // Card padding
  static const double cardPadding = 16.0;
  static const double cardPaddingLarge = 20.0;

  // List item spacing
  static const double listItemSpacing = 12.0;
  static const double listItemPadding = 16.0;

  // Button dimensions (minimum 48x48 for touch targets)
  static const double buttonHeight = 56.0; // Larger for older users
  static const double buttonMinWidth = 120.0;
  static const double buttonPadding = 16.0;

  // Touch target minimum (WCAG)
  static const double touchTarget = 48.0;

  // Room card dimensions
  static const double roomCardSize = 80.0;
  static const double roomCardSpacing = 12.0;

  // Icon sizes
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;
  static const double iconXl = 32.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 100.0;

  // Elevation
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;

  // Common EdgeInsets
  static const EdgeInsets paddingAll = EdgeInsets.all(md);
  static const EdgeInsets paddingHorizontal = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingVertical = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingScreen = EdgeInsets.all(screenPadding);
  static const EdgeInsets paddingCard = EdgeInsets.all(cardPadding);

  // Common SizedBox gaps
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  // Vertical gaps
  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalLg = SizedBox(height: lg);
  static const SizedBox gapVerticalXl = SizedBox(height: xl);

  // Horizontal gaps
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
  static const SizedBox gapHorizontalXl = SizedBox(width: xl);
}
