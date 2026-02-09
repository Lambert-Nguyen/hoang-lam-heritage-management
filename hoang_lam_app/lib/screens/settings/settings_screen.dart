import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/notification_provider.dart';
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
          _buildSectionHeader(context, l10n.security),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: l10n.changePassword,
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
                  '${l10n.loginWith} ${biometricState.biometricTypeName}',
                ),
                subtitle: Text(
                  biometricState.isEnabled
                      ? l10n.enabled
                      : l10n.fasterLoginBiometric,
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
                          SnackBar(
                            content: Text(l10n.biometricLoginEnabled),
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
                        SnackBar(
                          content: Text(l10n.biometricLoginDisabled),
                        ),
                      );
                    }
                  }
                },
              );
            },
            loading: () => ListTile(
              leading: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(l10n.loading),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Property Management section
          _buildSectionHeader(context, l10n.propertyManagement),
          _buildSettingsTile(
            context,
            icon: Icons.meeting_room,
            title: l10n.roomManagement,
            subtitle: l10n.addEditDeleteRooms,
            onTap: () {
              context.push(AppRoutes.roomManagement);
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.sell,
            title: l10n.priceManagement,
            subtitle: l10n.ratePlansPromotions,
            onTap: () {
              context.push(AppRoutes.pricing);
            },
          ),

          const Divider(),

          // General settings
          _buildSectionHeader(context, l10n.generalSettings),

          // Theme toggle
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: l10n.theme,
            subtitle: _getThemeModeText(l10n, settings.themeMode),
            onTap: () {
              _showThemePicker(context, ref, settings.themeMode);
            },
          ),

          // Language picker
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: l10n.language,
            subtitle: settings.locale == 'vi' ? l10n.vietnamese : 'English',
            onTap: () {
              _showLanguagePicker(context, ref, settings.locale);
            },
          ),

          // Text size picker
          _buildSettingsTile(
            context,
            icon: Icons.text_fields,
            title: l10n.textSize,
            subtitle: _getTextSizeText(l10n, settings.textScaleFactor),
            onTap: () {
              _showTextSizePicker(context, ref, settings.textScaleFactor);
            },
          ),

          // Notification settings
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: l10n.notificationsSettings,
            subtitle: _getNotificationText(l10n, settings),
            onTap: () {
              _showNotificationSettings(context, ref, settings);
            },
          ),

          const Divider(),

          // Management (admin only)
          if (currentUser?.isAdmin == true) ...[
            _buildSectionHeader(context, l10n.management),
            _buildSettingsTile(
              context,
              icon: Icons.nightlight_outlined,
              title: l10n.nightAudit,
              subtitle: l10n.checkDailyFigures,
              onTap: () {
                context.push(AppRoutes.nightAudit);
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.description_outlined,
              title: l10n.residenceDeclaration,
              subtitle: l10n.exportGuestListPolice,
              onTap: () {
                context.push(AppRoutes.declaration);
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.category_outlined,
              title: l10n.financialCategories,
              subtitle: 'Xem danh mục thu, chi',
              onTap: () {
                context.push(AppRoutes.financialCategories);
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.people_outline,
              title: l10n.accountManagement,
              subtitle: 'Xem danh sách nhân sự',
              onTap: () {
                context.push(AppRoutes.staffManagement);
              },
            ),
            const Divider(),
          ],

          // Data section
          _buildSectionHeader(context, l10n.data),
          _buildSettingsTile(
            context,
            icon: Icons.sync,
            title: l10n.syncData,
            subtitle: l10n.lastUpdateJustNow,
            onTap: () {
              // TODO: Manual sync
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.backup,
            title: l10n.backup,
            onTap: () {
              // TODO: Show backup options
            },
          ),

          const Divider(),

          // Help section
          _buildSectionHeader(context, l10n.support),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: l10n.userGuide,
            onTap: () {
              // TODO: Show help
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: l10n.aboutApp,
            subtitle: '${l10n.version} ${AppConstants.appVersion}',
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

  String _getThemeModeText(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.light,
      ThemeMode.dark => l10n.dark,
      ThemeMode.system => l10n.systemDefault,
    };
  }

  String _getTextSizeText(AppLocalizations l10n, double scaleFactor) {
    if (scaleFactor <= 0.85) return l10n.small;
    if (scaleFactor <= 1.0) return l10n.normal;
    if (scaleFactor <= 1.15) return l10n.large;
    return l10n.extraLarge;
  }

  String _getNotificationText(AppLocalizations l10n, AppSettings settings) {
    final enabled = <String>[];
    if (settings.notifyCheckIn) enabled.add('Check-in');
    if (settings.notifyCheckOut) enabled.add('Check-out');
    if (settings.notifyCleaning) enabled.add(l10n.roomCleaning);

    if (enabled.isEmpty) return l10n.allOff;
    return enabled.join(', ');
  }

  Widget _buildProfileSection(
      BuildContext context, WidgetRef ref, dynamic currentUser) {
    final l10n = context.l10n;
    final displayName = currentUser?.displayName ?? l10n.user;
    final roleDisplay = currentUser?.roleDisplay ?? l10n.staff;
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(l10n.systemDefault),
              subtitle: Text(l10n.autoPhoneSettings),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.light),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.dark),
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
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String current) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.vietnamese),
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
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showTextSizePicker(BuildContext context, WidgetRef ref, double current) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.textSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double>(
              title: Text(l10n.small, style: const TextStyle(fontSize: 12)),
              value: 0.85,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(0.85);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<double>(
              title: Text(l10n.normal, style: const TextStyle(fontSize: 14)),
              value: 1.0,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(1.0);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<double>(
              title: Text(l10n.large, style: const TextStyle(fontSize: 16)),
              value: 1.15,
              groupValue: current,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTextScaleFactor(1.15);
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<double>(
              title: Text(l10n.extraLarge, style: const TextStyle(fontSize: 18)),
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
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    final l10n = context.l10n;
    var notifyCheckIn = settings.notifyCheckIn;
    var notifyCheckOut = settings.notifyCheckOut;
    var notifyCleaning = settings.notifyCleaning;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.notificationSettings),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Backend-synced push notification toggle
                Consumer(
                  builder: (context, innerRef, _) {
                    final prefsAsync = innerRef.watch(notificationPreferencesProvider);
                    return prefsAsync.when(
                      data: (prefs) => SwitchListTile(
                        title: Text(l10n.pushNotifications),
                        subtitle: Text(l10n.receivePushNotifications),
                        value: prefs.receiveNotifications,
                        onChanged: (value) async {
                          try {
                            await innerRef
                                .read(notificationRepositoryProvider)
                                .updatePreferences(
                                  receiveNotifications: value,
                                );
                            innerRef.invalidate(notificationPreferencesProvider);
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${l10n.error}: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      loading: () => const ListTile(
                        leading: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Push notifications'),
                      ),
                      error: (_, __) => SwitchListTile(
                        title: Text(l10n.pushNotifications),
                        subtitle: Text(l10n.tapToRetry),
                        value: true,
                        onChanged: (_) {
                          innerRef.invalidate(notificationPreferencesProvider);
                        },
                      ),
                    );
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 8,
                    bottom: 4,
                  ),
                  child: Text(
                    l10n.localReminders,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.checkinReminder),
                  subtitle: Text(l10n.notifyCheckinToday),
                  value: notifyCheckIn,
                  onChanged: (value) {
                    setState(() => notifyCheckIn = value);
                    ref.read(settingsProvider.notifier).setNotifyCheckIn(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.checkoutReminder),
                  subtitle: Text(l10n.notifyCheckoutToday),
                  value: notifyCheckOut,
                  onChanged: (value) {
                    setState(() => notifyCheckOut = value);
                    ref.read(settingsProvider.notifier).setNotifyCheckOut(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.cleaningReminder),
                  subtitle: Text(l10n.notifyRoomNeedsCleaning),
                  value: notifyCleaning,
                  onChanged: (value) {
                    setState(() => notifyCleaning = value);
                    ref.read(settingsProvider.notifier).setNotifyCleaning(value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
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
        title: Text(l10n.confirmLogout),
        content: Text(l10n.confirmLogoutMessage),
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
