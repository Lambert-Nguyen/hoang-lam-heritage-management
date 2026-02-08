import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard.dart';

/// Dashboard occupancy widget showing occupancy rate and room status
class DashboardOccupancyWidget extends StatelessWidget {
  final OccupancySummary occupancy;
  final RoomStatusSummary roomStatus;

  const DashboardOccupancyWidget({
    super.key,
    required this.occupancy,
    required this.roomStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
              AppSpacing.gapHorizontalSm,
              Text(
                l10n.occupancyRate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // Occupancy percentage
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  // Background circle
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  // Progress circle
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: occupancy.rate / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getOccupancyColor(occupancy.rate),
                        ),
                      ),
                    ),
                  ),
                  // Center text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${occupancy.rate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getOccupancyColor(occupancy.rate),
                          ),
                        ),
                        Text(
                          '${occupancy.occupiedRooms}/${occupancy.totalRooms}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapVerticalMd,
          // Room status breakdown
          _buildStatusRow(l10n.available, roomStatus.available, AppColors.available),
          AppSpacing.gapVerticalSm,
          _buildStatusRow(l10n.occupied, roomStatus.occupied, AppColors.occupied),
          AppSpacing.gapVerticalSm,
          _buildStatusRow(l10n.cleaning, roomStatus.cleaning, AppColors.cleaning),
          if (roomStatus.maintenance > 0) ...[
            AppSpacing.gapVerticalSm,
            _buildStatusRow(
                l10n.maintenance, roomStatus.maintenance, AppColors.maintenance),
          ],
          if (roomStatus.blocked > 0) ...[
            AppSpacing.gapVerticalSm,
            _buildStatusRow(l10n.blocked, roomStatus.blocked, AppColors.blocked),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        AppSpacing.gapHorizontalSm,
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getOccupancyColor(double rate) {
    if (rate >= 80) return AppColors.occupied;
    if (rate >= 50) return AppColors.warning;
    return AppColors.available;
  }
}
