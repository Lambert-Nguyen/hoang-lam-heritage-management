import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/guest.dart';

/// A card widget displaying guest summary information
class GuestCard extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showVipBadge;
  final bool showBookingCount;

  const GuestCard({
    super.key,
    required this.guest,
    this.onTap,
    this.onLongPress,
    this.showVipBadge = true,
    this.showBookingCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Row(
            children: [
              _buildAvatar(context),
              AppSpacing.gapHorizontalMd,
              Expanded(child: _buildGuestInfo(context)),
              if (showVipBadge && guest.isVip) _buildVipBadge(context),
              AppSpacing.gapHorizontalSm,
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor:
          guest.isVip
              ? AppColors.warning.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        guest.initials,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: guest.isVip ? AppColors.warning : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildGuestInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                guest.fullName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalXs,
        Row(
          children: [
            const Icon(
              Icons.phone_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            AppSpacing.gapHorizontalXs,
            Text(
              guest.formattedPhone,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        AppSpacing.gapVerticalXs,
        Row(
          children: [
            _buildInfoChip(
              context,
              icon: guest.idType.icon,
              label: guest.idType.localizedName(context.l10n),
            ),
            AppSpacing.gapHorizontalSm,
            _buildInfoChip(
              context,
              icon: Icons.flag_outlined,
              label: guest.nationalityDisplay,
            ),
            if (showBookingCount && guest.bookingCount > 0) ...[
              AppSpacing.gapHorizontalSm,
              _buildInfoChip(
                context,
                icon: Icons.hotel_outlined,
                label: '${guest.bookingCount} ${context.l10n.timesCount}',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          AppSpacing.gapHorizontalXs,
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.warning),
          AppSpacing.gapHorizontalXs,
          Text(
            'VIP',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact card for guest selection (e.g., in booking form)
class GuestCompactCard extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final bool isSelected;

  const GuestCompactCard({
    super.key,
    required this.guest,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    guest.isVip
                        ? AppColors.warning.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  guest.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: guest.isVip ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      guest.formattedPhone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (guest.isVip)
                const Icon(Icons.star, size: 16, color: AppColors.warning),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
