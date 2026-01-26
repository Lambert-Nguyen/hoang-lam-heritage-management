import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../router/app_router.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentUser = ref.watch(currentUserProvider);
    final biometricAsync = ref.watch(biometricNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // User profile section
          _buildProfileSection(context, ref, currentUser),

          const Divider(),

          // Security settings
          _buildSectionHeader(context, 'Bảo mật'),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: () {
              context.push(AppRoutes.passwordChange);
            },
          ),
          // Biometric toggle
          biometricAsync.when(
            data: (biometricState) {
              if (!biometricState.isSupported) {
                return const SizedBox.shrink();
              }

              return SwitchListTile(
                secondary: Icon(
                  biometricState.biometricTypeName == 'Face ID'
                      ? Icons.face
                      : Icons.fingerprint,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Đăng nhập bằng ${biometricState.biometricTypeName}',
                ),
                subtitle: Text(
                  biometricState.isEnabled
                      ? 'Đã bật'
                      : 'Đăng nhập nhanh hơn với sinh trắc học',
                ),
                value: biometricState.isEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Enable biometric - requires authentication first
                    final authenticated = await ref
                        .read(biometricNotifierProvider.notifier)
                        .authenticate();
                    if (authenticated && currentUser != null) {
                      await ref
                          .read(biometricNotifierProvider.notifier)
                          .enableBiometric(currentUser.username);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Đã bật đăng nhập sinh trắc học'),
                          ),
                        );
                      }
                    }
                  } else {
                    // Disable biometric
                    await ref
                        .read(biometricNotifierProvider.notifier)
                        .disableBiometric();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã tắt đăng nhập sinh trắc học'),
                        ),
                      );
                    }
                  }
                },
              );
            },
            loading: () => const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Đang tải...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // General settings
          _buildSectionHeader(context, 'Cài đặt chung'),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Ngôn ngữ',
            subtitle: 'Tiếng Việt',
            onTap: () {
              // TODO: Show language picker
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.text_fields,
            title: 'Cỡ chữ',
            subtitle: 'Bình thường',
            onTap: () {
              // TODO: Show text size picker
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            subtitle: 'Bật',
            onTap: () {
              // TODO: Show notification settings
            },
          ),

          const Divider(),

          // Hotel settings (admin only)
          if (currentUser?.isAdmin == true) ...[
            _buildSectionHeader(context, 'Quản lý'),
            _buildSettingsTile(
              context,
              icon: Icons.hotel,
              title: 'Thông tin khách sạn',
              onTap: () {
                // TODO: Show hotel info
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.meeting_room,
              title: 'Quản lý phòng',
              onTap: () {
                // TODO: Show room management
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.category,
              title: 'Danh mục thu chi',
              onTap: () {
                // TODO: Show categories
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.people_outline,
              title: 'Quản lý tài khoản',
              onTap: () {
                // TODO: Show user management
              },
            ),
            const Divider(),
          ],

          // Data section
          _buildSectionHeader(context, 'Dữ liệu'),
          _buildSettingsTile(
            context,
            icon: Icons.sync,
            title: 'Đồng bộ dữ liệu',
            subtitle: 'Cập nhật lần cuối: Vừa xong',
            onTap: () {
              // TODO: Manual sync
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.backup,
            title: 'Sao lưu',
            onTap: () {
              // TODO: Show backup options
            },
          ),

          const Divider(),

          // Help section
          _buildSectionHeader(context, 'Hỗ trợ'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Hướng dẫn sử dụng',
            onTap: () {
              // TODO: Show help
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Thông tin ứng dụng',
            subtitle: 'Phiên bản ${AppConstants.appVersion}',
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const Divider(),

          // Logout
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: l10n.logout,
            textColor: AppColors.error,
            onTap: () {
              _showLogoutConfirmation(context, ref, l10n);
            },
          ),

          AppSpacing.gapVerticalXl,
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, WidgetRef ref, dynamic currentUser) {
    final displayName = currentUser?.displayName ?? 'Người dùng';
    final roleDisplay = currentUser?.roleDisplay ?? 'Nhân viên';
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Padding(
      padding: AppSpacing.paddingAll,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  roleDisplay,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Edit profile
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 14),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.hotelName,
      applicationVersion: 'Phiên bản ${AppConstants.appVersion}',
      applicationIcon: const Icon(
        Icons.hotel,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        const Text(
          'Ứng dụng quản lý nhà nghỉ đơn giản, dễ sử dụng dành cho gia đình.',
        ),
        AppSpacing.gapVerticalMd,
        const Text(
          'Phát triển bởi: Duy Lâm',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xác nhận ${l10n.logout.toLowerCase()}?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}
