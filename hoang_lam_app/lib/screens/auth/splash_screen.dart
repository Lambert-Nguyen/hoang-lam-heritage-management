import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/config/app_constants.dart';
import '../../models/auth.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

/// Splash screen shown during app initialization
/// Checks authentication status and redirects accordingly
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // Small delay for splash animation
    debugPrint('[SplashScreen] Starting auth check delay...');
    await Future.delayed(const Duration(milliseconds: 800));

    // Check auth status with a 10-second timeout fallback
    debugPrint('[SplashScreen] Calling checkAuthStatus...');
    try {
      await ref
          .read(authStateProvider.notifier)
          .checkAuthStatus()
          .timeout(const Duration(seconds: 10));
      debugPrint('[SplashScreen] checkAuthStatus completed');
    } catch (e) {
      debugPrint('[SplashScreen] checkAuthStatus timed out or failed: $e');
      if (mounted) {
        // Fall back to unauthenticated state so router redirects to login
        ref.read(authStateProvider.notifier).handleSessionExpired();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state - router will handle redirects automatically
    final authState = ref.watch(authStateProvider);
    debugPrint('[SplashScreen] Current auth state: $authState');

    // No manual navigation needed - router's redirect handles it
    authState.maybeWhen(
      authenticated: (_) {
        debugPrint(
          '[SplashScreen] Authenticated - router will redirect to home',
        );
      },
      unauthenticated: () {
        debugPrint(
          '[SplashScreen] Unauthenticated - router will redirect to login',
        );
      },
      orElse: () {
        debugPrint('[SplashScreen] Still loading: $authState');
      },
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepAccent.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/logo-vang.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Hotel Name
                    const Text(
                      AppConstants.hotelName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      context.l10n.apartmentManagement,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
