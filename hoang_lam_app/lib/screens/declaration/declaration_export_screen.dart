import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus, XFile;

import '../../l10n/app_localizations.dart';

import '../../core/utils/file_saver.dart' as file_saver;
import '../../models/declaration.dart';
import '../../providers/declaration_provider.dart';
import '../../core/theme/app_colors.dart';

/// Screen for exporting temporary residence declarations.
///
/// Supports two official Vietnamese forms:
/// - Mẫu ĐD10 (Nghị định 144/2021): Sổ quản lý lưu trú — Vietnamese guests
/// - Mẫu NA17 (Thông tư 04/2015): Phiếu khai báo tạm trú — Foreign guests
class DeclarationExportScreen extends ConsumerStatefulWidget {
  const DeclarationExportScreen({super.key});

  @override
  ConsumerState<DeclarationExportScreen> createState() =>
      _DeclarationExportScreenState();
}

class _DeclarationExportScreenState
    extends ConsumerState<DeclarationExportScreen> {
  DateTime _dateFrom = DateTime.now();
  DateTime _dateTo = DateTime.now();
  ExportFormat _format = ExportFormat.excel;
  DeclarationFormType _formType = DeclarationFormType.all;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exportState = ref.watch(declarationExportProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for state changes
    ref.listen<DeclarationExportState>(declarationExportProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        success: (filePath) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportSuccess),
              action: file_saver.isWebPlatform
                  ? null
                  : SnackBarAction(
                      label: l10n.open,
                      onPressed: () => _openFile(filePath),
                    ),
              duration: const Duration(seconds: 5),
            ),
          );
        },
        error: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $message'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.residenceDeclarationTitle), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.info,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.exportGuestListDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.declarationFormDescriptions,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form type selection
            Text(
              context.l10n.formType,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DeclarationFormType.values.map((type) {
                final isSelected = _formType == type;
                return ChoiceChip(
                  label: Text(type.localizedName(context.l10n)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _formType = type);
                    }
                  },
                );
              }).toList(),
            ),
            if (_formType != DeclarationFormType.all) ...[
              const SizedBox(height: 4),
              Text(
                _formType.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Date range section
            Text(
              l10n.dateRangeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: l10n.fromDate,
                    date: _dateFrom,
                    dateFormat: _dateFormat,
                    onDateSelected: (date) {
                      setState(() {
                        _dateFrom = date;
                        if (_dateTo.isBefore(_dateFrom)) {
                          _dateTo = _dateFrom;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: l10n.toDate,
                    date: _dateTo,
                    dateFormat: _dateFormat,
                    firstDate: _dateFrom,
                    onDateSelected: (date) {
                      setState(() {
                        _dateTo = date;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick select buttons
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: Text(l10n.today),
                  onPressed: () {
                    setState(() {
                      _dateFrom = DateTime.now();
                      _dateTo = DateTime.now();
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.yesterday),
                  onPressed: () {
                    final yesterday = DateTime.now().subtract(
                      const Duration(days: 1),
                    );
                    setState(() {
                      _dateFrom = yesterday;
                      _dateTo = yesterday;
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.last7DaysLabel),
                  onPressed: () {
                    setState(() {
                      _dateTo = DateTime.now();
                      _dateFrom = DateTime.now().subtract(
                        const Duration(days: 6),
                      );
                    });
                  },
                ),
                ActionChip(
                  label: Text(l10n.last30DaysLabel),
                  onPressed: () {
                    setState(() {
                      _dateTo = DateTime.now();
                      _dateFrom = DateTime.now().subtract(
                        const Duration(days: 29),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Format section
            Text(
              l10n.fileFormatLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormatCard(
                    format: ExportFormat.excel,
                    isSelected: _format == ExportFormat.excel,
                    onTap: () => setState(() => _format = ExportFormat.excel),
                    subtitle: l10n.excelFormatDesc,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FormatCard(
                    format: ExportFormat.csv,
                    isSelected: _format == ExportFormat.csv,
                    onTap: () => setState(() => _format = ExportFormat.csv),
                    subtitle: l10n.csvFormatDesc,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Export button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: exportState is DeclarationExportLoading
                    ? null
                    : _handleExport,
                icon: exportState is DeclarationExportLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  exportState is DeclarationExportLoading
                      ? l10n.exporting
                      : l10n.exportList,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Show last exported file
            if (exportState is DeclarationExportSuccess)
              _ExportedFileCard(
                filePath: exportState.filePath,
                isWeb: file_saver.isWebPlatform,
                onOpen: () => _openFile(exportState.filePath),
                onShare: () => _shareFile(exportState.filePath),
              ),
          ],
        ),
      ),
    );
  }

  void _handleExport() {
    ref
        .read(declarationExportProvider.notifier)
        .export(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          format: _format,
          formType: _formType,
        );
  }

  Future<void> _openFile(String filePath) async {
    final l10n = context.l10n;
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.cannotOpenFile}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareFile(String filePath) async {
    final l10n = context.l10n;
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.cannotShareFile}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Date picker field widget
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat dateFormat;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.dateFormat,
    required this.onDateSelected,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(dateFormat.format(date)),
      ),
    );
  }
}

/// Format selection card
class _FormatCard extends StatelessWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback onTap;
  final String subtitle;

  const _FormatCard({
    required this.format,
    required this.isSelected,
    required this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              format == ExportFormat.csv
                  ? Icons.description
                  : Icons.table_chart,
              size: 32,
              color: isSelected ? colorScheme.primary : null,
            ),
            const SizedBox(height: 8),
            Text(
              format.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : null,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card showing exported file info
class _ExportedFileCard extends StatelessWidget {
  final String filePath;
  final bool isWeb;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  const _ExportedFileCard({
    required this.filePath,
    this.isWeb = false,
    required this.onOpen,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filename = filePath.split('/').last;

    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.fileExportedSuccess,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(filename, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              l10n.bookingsMarkedAsDeclared,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!isWeb)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.openFileBtn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(l10n.shareFileBtn),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.fileDownloadedByBrowser,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
