import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/night_audit.dart';
import '../../providers/night_audit_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Night Audit Screen - Phase 2 (1.12)
/// Shows daily audit summary with room, booking, and financial statistics
class NightAuditScreen extends ConsumerStatefulWidget {
  const NightAuditScreen({super.key});

  @override
  ConsumerState<NightAuditScreen> createState() => _NightAuditScreenState();
}

class _NightAuditScreenState extends ConsumerState<NightAuditScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayAuditAsync = ref.watch(todayAuditProvider);
    final state = ref.watch(nightAuditNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nightAuditTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAuditHistory,
            tooltip: l10n.historyLabel,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: l10n.selectDate,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: todayAuditAsync.when(
          data: (audit) => _buildAuditContent(context, audit),
          loading: () => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const LoadingIndicator(),
              ),
            ),
          ),
          error: (error, stack) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: ErrorDisplay(
                  message: '${l10n.auditLoadError}: $error',
                  onRetry: _refreshData,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: todayAuditAsync.maybeWhen(
        data: (audit) => _buildBottomActions(context, audit, state),
        orElse: () => null,
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(todayAuditProvider);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      // Create or fetch audit for selected date
      await ref.read(nightAuditNotifierProvider.notifier).createAudit(date);
    }
  }

  void _showAuditHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            _AuditHistorySheet(scrollController: scrollController),
      ),
    );
  }

  Widget _buildAuditContent(BuildContext context, NightAudit audit) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and status header
          _buildHeader(audit),
          AppSpacing.gapVerticalMd,

          // Room statistics
          _buildRoomStats(audit),
          AppSpacing.gapVerticalMd,

          // Booking statistics
          _buildBookingStats(audit),
          AppSpacing.gapVerticalMd,

          // Financial summary
          _buildFinancialSummary(audit),
          AppSpacing.gapVerticalMd,

          // Payment breakdown
          _buildPaymentBreakdown(audit),
          AppSpacing.gapVerticalMd,

          // Notes
          if (audit.notes.isNotEmpty) _buildNotes(audit),
          AppSpacing.gapVerticalLg,
        ],
      ),
    );
  }

  Widget _buildHeader(NightAudit audit) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd/MM/yyyy', 'vi').format(audit.auditDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                audit.performedByName != null
                    ? '${l10n.performedBy}: ${audit.performedByName}'
                    : l10n.notCompleted,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: audit.status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(audit.status.icon, size: 16, color: audit.status.color),
              AppSpacing.gapHorizontalXs,
              Text(
                audit.status.localizedName(context.l10n),
                style: TextStyle(
                  color: audit.status.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoomStats(NightAudit audit) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hotel, color: AppColors.primary),
              AppSpacing.gapHorizontalSm,
              Text(
                l10n.roomStatistics,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${audit.occupancyRate.toStringAsFixed(0)}% ${context.l10n.occupancyFilled}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Row(
            children: [
              _buildStatItem(
                context.l10n.totalRooms,
                audit.totalRooms.toString(),
                Icons.king_bed,
              ),
              _buildStatItem(
                context.l10n.occupied,
                audit.roomsOccupied.toString(),
                Icons.person,
                color: AppColors.roomOccupied,
              ),
              _buildStatItem(
                context.l10n.available,
                audit.roomsAvailable.toString(),
                Icons.check_circle,
                color: AppColors.roomAvailable,
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,
          Row(
            children: [
              _buildStatItem(
                context.l10n.cleaning,
                audit.roomsCleaning.toString(),
                Icons.cleaning_services,
                color: AppColors.roomCleaning,
              ),
              _buildStatItem(
                context.l10n.maintenance,
                audit.roomsMaintenance.toString(),
                Icons.build,
                color: AppColors.roomMaintenance,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStats(NightAudit audit) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primary),
              AppSpacing.gapHorizontalSm,
              Text(
                context.l10n.bookingStatistics,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Row(
            children: [
              _buildStatItem(
                'Check-in',
                audit.checkInsToday.toString(),
                Icons.login,
                color: AppColors.success,
              ),
              _buildStatItem(
                'Check-out',
                audit.checkOutsToday.toString(),
                Icons.logout,
                color: AppColors.info,
              ),
              _buildStatItem(
                context.l10n.newBookings,
                audit.newBookings.toString(),
                Icons.add_circle,
                color: AppColors.primary,
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,
          Row(
            children: [
              _buildStatItem(
                context.l10n.noShows,
                audit.noShows.toString(),
                Icons.person_off,
                color: AppColors.warning,
              ),
              _buildStatItem(
                context.l10n.cancellationsLabel,
                audit.cancellations.toString(),
                Icons.cancel,
                color: AppColors.error,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(NightAudit audit) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
              AppSpacing.gapHorizontalSm,
              Text(
                context.l10n.financialOverview,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          _buildFinancialRow(
            context.l10n.totalIncome,
            audit.totalIncome,
            isIncome: true,
          ),
          _buildFinancialRow(
            '  - ${context.l10n.roomRevenue}',
            audit.roomRevenue,
            isSubItem: true,
          ),
          _buildFinancialRow(
            '  - ${context.l10n.otherRevenue}',
            audit.otherRevenue,
            isSubItem: true,
          ),
          const Divider(height: AppSpacing.md),
          _buildFinancialRow(
            context.l10n.totalExpense,
            audit.totalExpense,
            isExpense: true,
          ),
          const Divider(height: AppSpacing.md),
          _buildFinancialRow(
            context.l10n.netProfit,
            audit.netRevenue,
            isProfit: true,
            isBold: true,
          ),
          if (audit.pendingPayments > 0) ...[
            const Divider(height: AppSpacing.md),
            _buildFinancialRow(
              '${context.l10n.pendingPayments} (${audit.unpaidBookingsCount} ${context.l10n.bookings})',
              audit.pendingPayments,
              color: AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(NightAudit audit) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, color: AppColors.primary),
              AppSpacing.gapHorizontalSm,
              Text(
                context.l10n.paymentDetails,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          _buildPaymentRow(context.l10n.cash, audit.cashCollected, Icons.money),
          _buildPaymentRow(
            context.l10n.bankTransfer,
            audit.bankTransferCollected,
            Icons.account_balance,
          ),
          _buildPaymentRow('MoMo', audit.momoCollected, Icons.phone_android),
          _buildPaymentRow(
            context.l10n.otherPayment,
            audit.otherPayments,
            Icons.more_horiz,
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(NightAudit audit) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, color: AppColors.primary),
              AppSpacing.gapHorizontalSm,
              Text(
                context.l10n.notes,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,
          Text(audit.notes),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color ?? AppColors.textSecondary, size: 24),
          AppSpacing.gapVerticalXs,
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    double amount, {
    bool isIncome = false,
    bool isExpense = false,
    bool isProfit = false,
    bool isSubItem = false,
    bool isBold = false,
    Color? color,
  }) {
    Color textColor = color ?? AppColors.textPrimary;
    if (isIncome) textColor = AppColors.income;
    if (isExpense) textColor = AppColors.expense;
    if (isProfit) {
      textColor = amount >= 0 ? AppColors.income : AppColors.expense;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSubItem ? AppColors.textSecondary : null,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: textColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          AppSpacing.gapHorizontalSm,
          Expanded(child: Text(label)),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions(
    BuildContext context,
    NightAudit audit,
    NightAuditState state,
  ) {
    if (audit.status == NightAuditStatus.closed) {
      return null;
    }

    return Container(
      padding: AppSpacing.paddingAll,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepAccent.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.isLoading ? null : _recalculateAudit,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.recalculate),
            ),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: state.isClosing ? null : () => _closeAudit(audit),
              icon: state.isClosing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock),
              label: Text(
                state.isClosing
                    ? context.l10n.closingAudit
                    : context.l10n.closeAuditBtn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recalculateAudit() async {
    final audit = ref.read(todayAuditProvider).valueOrNull;
    if (audit == null) return;

    final result = await ref
        .read(nightAuditNotifierProvider.notifier)
        .recalculateAudit(audit.id);
    if (!mounted) return;

    if (result != null) {
      ref.invalidate(todayAuditProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.statsRecalculated)));
    } else {
      final error = ref.read(nightAuditNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.recalculateError}: ${error ?? context.l10n.unknownError}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _closeAudit(NightAudit audit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.closeAuditBtn),
        content: Text(context.l10n.closeAuditConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.closeAuditBtn),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref
          .read(nightAuditNotifierProvider.notifier)
          .closeAudit(audit.id);
      if (!mounted) return;

      if (result != null) {
        ref.invalidate(todayAuditProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.auditClosed)));
      } else {
        final error = ref.read(nightAuditNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.closeAuditError}: ${error ?? context.l10n.unknownError}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Audit history bottom sheet
class _AuditHistorySheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _AuditHistorySheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditsAsync = ref.watch(nightAuditsProvider);

    return Column(
      children: [
        Container(
          padding: AppSpacing.paddingAll,
          child: Row(
            children: [
              Text(
                context.l10n.auditHistory,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: auditsAsync.when(
            data: (audits) {
              if (audits.isEmpty) {
                return Center(child: Text(context.l10n.noAuditsYet));
              }
              return ListView.builder(
                controller: scrollController,
                padding: AppSpacing.paddingAll,
                itemCount: audits.length,
                itemBuilder: (context, index) {
                  final audit = audits[index];
                  return _buildAuditHistoryItem(context, audit);
                },
              );
            },
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorDisplay(
              message: '${context.l10n.loadHistoryError}: $e',
              onRetry: () => ref.invalidate(nightAuditsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditHistoryItem(
    BuildContext context,
    NightAuditListItem audit,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {
        _showAuditDetailDialog(context, audit);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy').format(audit.auditDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: audit.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  audit.status.localizedName(context.l10n),
                  style: TextStyle(color: audit.status.color, fontSize: 12),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,
          Row(
            children: [
              _buildMiniStat(
                context.l10n.room,
                '${audit.roomsOccupied}/${audit.totalRooms}',
              ),
              _buildMiniStat(
                context.l10n.occupancy,
                '${audit.occupancyRate.toStringAsFixed(0)}%',
              ),
              _buildMiniStat(
                context.l10n.revenueShort,
                CurrencyFormatter.formatCompact(audit.totalIncome),
              ),
              _buildMiniStat(
                context.l10n.profitShort,
                CurrencyFormatter.formatCompact(audit.netRevenue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showAuditDetailDialog(BuildContext context, NightAuditListItem audit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Audit ${DateFormat('dd/MM/yyyy').format(audit.auditDate)}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context.l10n.statusLabel,
                audit.status.localizedName(context.l10n),
              ),
              _buildDetailRow(
                context.l10n.room,
                '${audit.roomsOccupied}/${audit.totalRooms}',
              ),
              _buildDetailRow(
                context.l10n.occupancyRate,
                '${audit.occupancyRate.toStringAsFixed(1)}%',
              ),
              _buildDetailRow(
                context.l10n.totalIncome,
                CurrencyFormatter.format(audit.totalIncome),
              ),
              _buildDetailRow(
                context.l10n.totalExpense,
                CurrencyFormatter.format(audit.totalExpense),
              ),
              _buildDetailRow(
                context.l10n.netProfit,
                CurrencyFormatter.format(audit.netRevenue),
              ),
              if (audit.performedByName != null)
                _buildDetailRow(
                  context.l10n.performedBy,
                  audit.performedByName!,
                ),
              if (audit.performedAt != null)
                _buildDetailRow(
                  context.l10n.timeLabel,
                  DateFormat('dd/MM/yyyy HH:mm').format(audit.performedAt!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.closeButton),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
