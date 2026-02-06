import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/settings_provider.dart';
import '../../router/app_router.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentUser = ref.watch(currentUserProvider);
    final biometricAsync = ref.watch(biometricNotifierProvider);
    final settings = ref.watch(settingsProvider);

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
                            content: Text('Đã bật đăng nhập sinh trắc học'),
                          ),
                        );
                      }
                    }
                  } else {
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

          // Property Management section
          _buildSectionHeader(context, 'Quản lý căn hộ'),
          _buildSettingsTile(
            context,
            icon: Icons.meeting_room,
            title: 'Quản lý phòng',
            subtitle: 'Thêm, sửa, xóa phòng',
            onTap: () {
              context.push(AppRoutes.roomManagement);
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.sell,
            title: 'Quản lý giá',
            subtitle: 'Gói giá, giá theo ngày, khuyến mãi',
            onTap: () {
              context.push(AppRoutes.pricing);
            },
          ),

          const Divider(),

          // General settings
          _buildSectionHeader(context, 'Cài đặt chung'),

          // Theme toggle
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Giao diện',
            subtitle: _getThemeModeText(settings.themeMode),
            onTap: () {
              _showThemePicker(context, ref, settings.themeMode);
            },
          ),

          // Language picker
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Ngôn ngữ',
            subtitle: settings.locale == 'vi' ? 'Tiếng Việt' : 'English',
            onTap: () {
              _showLanguagePicker(context, ref, settings.locale);
            },
          ),

          // Text size picker
          _buildSettingsTile(
            context,
            icon: Icons.text_fields,
            title: 'Cỡ chữ',
            subtitle: _getTextSizeText(settings.textScaleFactor),
            onTap: () {
              _showTextSizePicker(context, ref, settings.textScaleFactor);
            },
          ),

          // Notification settings
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Thông báo',
            subtitle: _getNotificationText(settings),
            onTap: () {
              _showNotificationSettings(context, ref, settings);
            },
          ),

          const Divider(),

          // Hotel management (admin only)
          if (currentUser?.isAdmin == true) ...[
            _buildSectionHeader(context, 'Quản lý'),
            _buildSettingsTile(
              context,
              icon: Icons.nightlight_outlined,
              title: 'Chốt ca đêm',
              subtitle: 'Kiểm tra số liệu cuối ngày',
              onTap: () {
                context.push(AppRoutes.nightAudit);
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.description_outlined,
              title: 'Khai báo lưu trú',
              subtitle: 'Xuất danh sách khách cho công an',
              onTap: () {
                context.push(AppRoutes.declaration);
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.category_outlined,
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

  String _getThemeModeText(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Sáng',
      ThemeMode.dark => 'Tối',
      ThemeMode.system => 'Theo hệ thống',
    };
  }

  String _getTextSizeText(double scaleFactor) {
    if (scaleFactor <= 0.85) return 'Nhỏ';
    if (scaleFactor <= 1.0) return 'Bình thường';
    if (scaleFactor <= 1.15) return 'Lớn';
    return 'Rất lớn';
  }

  String _getNotificationText(AppSettings settings) {
    final enabled = <String>[];
    if (settings.notifyCheckIn) enabled.add('Check-in');
    if (settings.notifyCheckOut) enabled.add('Check-out');
    if (settings.notifyCleaning) enabled.add('Dọn phòng');

    if (enabled.isEmpty) return 'Tắt tất cả';
    return enabled.join(', ');
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

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn giao diện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Theo hệ thống'),
              subtitle: const Text('Tự động theo cài đặt điện thoại'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sáng'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Tối'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setLocale('vi');
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setLocale('en');
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showTextSizePicker(BuildContext context, WidgetRef ref, double current) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cỡ chữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double>(
              title: const Text('Nhỏ', style: TextStyle(fontSize: 12)),
              value: 0.85,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(0.85);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<double>(
              title: const Text('Bình thường', style: TextStyle(fontSize: 14)),
              value: 1.0,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(1.0);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<double>(
              title: const Text('Lớn', style: TextStyle(fontSize: 16)),
              value: 1.15,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(1.15);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<double>(
              title: const Text('Rất lớn', style: TextStyle(fontSize: 18)),
              value: 1.3,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(1.3);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cài đặt thông báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('Nhắc nhở check-in'),
                subtitle: const Text('Thông báo khi có khách check-in hôm nay'),
                value: settings.notifyCheckIn,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNotifyCheckIn(value);
                },
              ),
              SwitchListTile(
                title: const Text('Nhắc nhở check-out'),
                subtitle: const Text('Thông báo khi có khách check-out hôm nay'),
                value: settings.notifyCheckOut,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNotifyCheckOut(value);
                },
              ),
              SwitchListTile(
                title: const Text('Nhắc nhở dọn phòng'),
                subtitle: const Text('Thông báo khi có phòng cần dọn dẹp'),
                value: settings.notifyCleaning,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNotifyCleaning(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.hotelName,
      applicationVersion: 'Phiên bản ${AppConstants.appVersion}',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logo-vang.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
      children: [
        const Text(
          'Ứng dụng quản lý căn hộ đơn giản, dễ sử dụng dành cho gia đình.',
        ),
        AppSpacing.gapVerticalMd,
        const Text(
          'Phát triển bởi: Duy Lâm',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        AppSpacing.gapVerticalSm,
        const Text(
          '© 2024 Hoàng Lâm Heritage Suites. All rights reserved.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
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
