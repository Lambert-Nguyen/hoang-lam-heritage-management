import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/app_constants.dart';
import '../../models/auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    // Try biometric login automatically on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricLogin();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricLogin() async {
    final biometricState = await ref.read(biometricNotifierProvider.future);

    if (biometricState.canUseBiometric) {
      await _handleBiometricLogin();
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _biometricLoading = true;
      _errorMessage = null;
    });

    try {
      final biometricNotifier = ref.read(biometricNotifierProvider.notifier);
      final authenticated = await biometricNotifier.authenticate();

      if (authenticated) {
        // Get stored username and use cached token
        final biometricState = await ref.read(biometricNotifierProvider.future);
        final storedUsername = biometricState.storedUsername;

        if (storedUsername != null) {
          // Check if we still have a valid session
          await ref.read(authStateProvider.notifier).checkAuthStatus();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Xác thực sinh trắc học thất bại';
      });
    } finally {
      if (mounted) {
        setState(() => _biometricLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    await ref.read(authStateProvider.notifier).login(username, password);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) async {
          // Enable biometric for this user after successful login
          final biometricState =
              await ref.read(biometricNotifierProvider.future);
          if (biometricState.isSupported && !biometricState.isEnabled) {
            // Show dialog to enable biometric
            if (mounted) {
              _showEnableBiometricDialog(user.username);
            }
          }

          // Navigate to home on successful login
          if (mounted) {
            context.go(AppRoutes.home);
          }
        },
        error: (message) {
          // Show error message
          setState(() => _errorMessage = message);
        },
        orElse: () {},
      );
    });

    final isLoading = ref.watch(isAuthLoadingProvider);
    final biometricAsync = ref.watch(biometricNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapVerticalXl,
                AppSpacing.gapVerticalXl,

                // Logo/Title
                Center(
                  child: Image.asset(
                    'assets/images/logo-vang.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                AppSpacing.gapVerticalMd,
                const Text(
                  AppConstants.hotelName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapVerticalSm,
                Text(
                  'Đăng nhập để quản lý',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.gapVerticalXl,
                AppSpacing.gapVerticalXl,

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapVerticalMd,
                ],

                // Username field
                AppTextField(
                  controller: _usernameController,
                  label: 'Tên đăng nhập',
                  hint: 'Nhập tên đăng nhập',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading && !_biometricLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    return null;
                  },
                ),

                AppSpacing.gapVerticalMd,

                // Password field
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading && !_biometricLoading,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Mật khẩu phải có ít nhất ${AppConstants.minPasswordLength} ký tự';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _handleLogin(),
                ),

                AppSpacing.gapVerticalXl,

                // Login button
                AppButton(
                  label: 'Đăng nhập',
                  onPressed: isLoading || _biometricLoading ? null : _handleLogin,
                  isLoading: isLoading,
                ),

                // Biometric login button
                biometricAsync.when(
                  data: (biometricState) {
                    if (!biometricState.canUseBiometric) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        AppSpacing.gapVerticalMd,
                        _BiometricLoginButton(
                          biometricTypeName: biometricState.biometricTypeName,
                          isLoading: _biometricLoading,
                          onPressed: isLoading || _biometricLoading
                              ? null
                              : _handleBiometricLogin,
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                AppSpacing.gapVerticalMd,

                // Forgot password (optional - not implemented for family app)
                AppTextButton(
                  label: 'Quên mật khẩu?',
                  onPressed: isLoading || _biometricLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng liên hệ quản trị viên để đặt lại mật khẩu',
                              ),
                            ),
                          );
                        },
                ),

                AppSpacing.gapVerticalXl,

                // Version info
                Text(
                  'Phiên bản ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnableBiometricDialog(String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kích hoạt đăng nhập sinh trắc học'),
        content: const Text(
          'Bạn có muốn sử dụng vân tay hoặc Face ID để đăng nhập nhanh hơn trong lần tới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(biometricNotifierProvider.notifier)
                  .enableBiometric(username);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã kích hoạt đăng nhập sinh trắc học'),
                  ),
                );
              }
            },
            child: const Text('Kích hoạt'),
          ),
        ],
      ),
    );
  }
}

/// Biometric login button widget
class _BiometricLoginButton extends StatelessWidget {
  final String biometricTypeName;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _BiometricLoginButton({
    required this.biometricTypeName,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              biometricTypeName == 'Face ID'
                  ? Icons.face
                  : Icons.fingerprint,
              size: 24,
            ),
      label: Text(
        isLoading ? 'Đang xác thực...' : 'Đăng nhập bằng $biometricTypeName',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
