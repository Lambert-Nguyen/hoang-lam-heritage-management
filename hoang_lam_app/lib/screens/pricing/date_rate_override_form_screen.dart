import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/rate_plan.dart';
import '../../models/room.dart';
import '../../providers/rate_plan_provider.dart';
import '../../providers/room_provider.dart';

/// Date Rate Override Form Screen for creating and editing date-specific pricing
class DateRateOverrideFormScreen extends ConsumerStatefulWidget {
  final int? overrideId; // null for new override

  const DateRateOverrideFormScreen({super.key, this.overrideId});

  @override
  ConsumerState<DateRateOverrideFormScreen> createState() =>
      _DateRateOverrideFormScreenState();
}

class _DateRateOverrideFormScreenState
    extends ConsumerState<DateRateOverrideFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _rateController;
  late TextEditingController _reasonController;
  late TextEditingController _minStayController;

  int? _selectedRoomTypeId;
  DateTime? _selectedDate;
  DateTime? _endDate; // For bulk creation
  bool _isBulkMode = false;
  bool _closedToArrival = false;
  bool _closedToDeparture = false;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool get _isEditing => widget.overrideId != null;

  // Common reasons built from l10n
  List<String> _getCommonReasons(AppLocalizations l10n) => [
    l10n.weekend,
    l10n.holiday,
    l10n.tetHoliday,
    l10n.christmas,
    l10n.summerSeason,
    l10n.lowSeason,
    l10n.promotion,
    l10n.specialEvent,
  ];

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController();
    _reasonController = TextEditingController();
    _minStayController = TextEditingController();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _reasonController.dispose();
    _minStayController.dispose();
    super.dispose();
  }

  void _initFromOverride(DateRateOverride override) {
    if (_isInitialized) return;
    _isInitialized = true;

    _rateController.text = override.rate.toInt().toString();
    _reasonController.text = override.reason;
    _minStayController.text = override.minStay?.toString() ?? '';

    _selectedRoomTypeId = override.roomType;
    _selectedDate = override.date;
    _closedToArrival = override.closedToArrival;
    _closedToDeparture = override.closedToDeparture;
  }

  @override
  Widget build(BuildContext context) {
    final roomTypesAsync = ref.watch(roomTypesProvider);

    // Load existing override for editing
    if (_isEditing) {
      final l10n = AppLocalizations.of(context)!;
      final overrideAsync = ref.watch(
        dateRateOverrideByIdProvider(widget.overrideId!),
      );
      return overrideAsync.when(
        data: (override) {
          _initFromOverride(override);
          return _buildForm(roomTypesAsync);
        },
        loading:
            () => Scaffold(
              appBar: AppBar(title: Text(l10n.editDateRate)),
              body: const Center(child: CircularProgressIndicator()),
            ),
        error:
            (error, _) => Scaffold(
              appBar: AppBar(title: Text(l10n.editDateRate)),
              body: Center(child: Text('${l10n.error}: $error')),
            ),
      );
    }

    return _buildForm(roomTypesAsync);
  }

  Widget _buildForm(AsyncValue<List<RoomType>> roomTypesAsync) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editDateRate : l10n.addDateRate),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: l10n.delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Bulk mode toggle (only for new)
            if (!_isEditing) ...[
              SwitchListTile(
                title: Text(l10n.createForMultipleDays),
                subtitle: Text(l10n.applyForDateRange),
                value: _isBulkMode,
                onChanged: (value) => setState(() => _isBulkMode = value),
                secondary: const Icon(Icons.date_range),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Room Type
            _buildSectionHeader(l10n.roomType),
            roomTypesAsync.when(
              data:
                  (roomTypes) => DropdownButtonFormField<int>(
                    value: _selectedRoomTypeId,
                    decoration: InputDecoration(
                      labelText: '${l10n.selectRoomType} *',
                      prefixIcon: const Icon(Icons.meeting_room),
                    ),
                    items:
                        roomTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type.id,
                                child: Text(
                                  '${type.name} - ${type.formattedBaseRate}',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() => _selectedRoomTypeId = value),
                    validator: (value) {
                      if (value == null) {
                        return l10n.pleaseSelectRoomType;
                      }
                      return null;
                    },
                  ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(l10n.cannotLoadRoomTypes),
            ),

            AppSpacing.gapVerticalLg,

            // Date Selection
            _buildSectionHeader(_isBulkMode ? l10n.dateRange : l10n.applyDate),

            if (_isBulkMode) ...[
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: '${l10n.fromDateRequired} *',
                      value: _selectedDate,
                      onChanged: (date) => setState(() => _selectedDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DatePickerField(
                      label: '${l10n.toDateRequired} *',
                      value: _endDate,
                      onChanged: (date) => setState(() => _endDate = date),
                      firstDate: _selectedDate,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _DatePickerField(
                label: '${l10n.selectDateRequired} *',
                value: _selectedDate,
                onChanged: (date) => setState(() => _selectedDate = date),
              ),
            ],

            AppSpacing.gapVerticalLg,

            // Rate
            _buildSectionHeader(l10n.priceSection),
            TextFormField(
              controller: _rateController,
              decoration: InputDecoration(
                labelText: l10n.priceForThisDate,
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: l10n.vndSuffix,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseEnterPrice;
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return l10n.priceMustBePositive;
                }
                return null;
              },
            ),

            AppSpacing.gapVerticalLg,

            // Reason
            _buildSectionHeader(l10n.reasonLabel),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: l10n.rateAdjustmentReason,
                hintText: l10n.rateReasonHint,
                prefixIcon: const Icon(Icons.info_outline),
              ),
            ),

            AppSpacing.gapVerticalSm,

            // Quick reason chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _getCommonReasons(l10n)
                      .map(
                        (reason) => ActionChip(
                          label: Text(reason),
                          onPressed:
                              () => setState(
                                () => _reasonController.text = reason,
                              ),
                          backgroundColor:
                              _reasonController.text == reason
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : null,
                        ),
                      )
                      .toList(),
            ),

            AppSpacing.gapVerticalLg,

            // Restrictions Section
            _buildSectionHeader(l10n.restrictionsOptional),

            SwitchListTile(
              title: Text(l10n.closeForArrival),
              subtitle: Text(l10n.noCheckinAllowed),
              value: _closedToArrival,
              onChanged: (value) => setState(() => _closedToArrival = value),
              secondary: Icon(
                Icons.no_meeting_room,
                color: _closedToArrival ? AppColors.warning : null,
              ),
            ),

            SwitchListTile(
              title: Text(l10n.closeForDeparture),
              subtitle: Text(l10n.noCheckoutAllowed),
              value: _closedToDeparture,
              onChanged: (value) => setState(() => _closedToDeparture = value),
              secondary: Icon(
                Icons.exit_to_app,
                color: _closedToDeparture ? AppColors.warning : null,
              ),
            ),

            AppSpacing.gapVerticalMd,

            // Min Stay
            TextFormField(
              controller: _minStayController,
              decoration: InputDecoration(
                labelText: l10n.minNightsOptional,
                hintText: l10n.minNightsRequired,
                prefixIcon: const Icon(Icons.nights_stay),
              ),
              keyboardType: TextInputType.number,
            ),

            AppSpacing.gapVerticalXl,

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveOverride,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save),
              label: Text(
                _isEditing
                    ? l10n.update
                    : _isBulkMode
                    ? l10n.createPriceMultipleDays
                    : l10n.createDateRate,
              ),
            ),

            AppSpacing.gapVerticalXl,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _saveOverride() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selectedRoomTypeId == null) {
      _showError(l10n.pleaseSelectRoomType);
      return;
    }
    if (_selectedDate == null) {
      _showError(l10n.pleaseSelectDate);
      return;
    }
    if (_isBulkMode && _endDate == null) {
      _showError(l10n.pleaseSelectEndDate);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(dateRateOverrideNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.updateOverride(widget.overrideId!, {
          'room_type': _selectedRoomTypeId,
          'date': _selectedDate!.toIso8601String().split('T')[0],
          'rate': int.parse(_rateController.text),
          'reason': _reasonController.text.trim(),
          'closed_to_arrival': _closedToArrival,
          'closed_to_departure': _closedToDeparture,
          'min_stay':
              _minStayController.text.isEmpty
                  ? null
                  : int.parse(_minStayController.text),
        });

        if (mounted) {
          ref.invalidate(dateRateOverridesProvider);
          _showSuccess(l10n.dateRateUpdated);
          Navigator.of(context).pop(true);
        }
      } else if (_isBulkMode) {
        // Bulk create
        final request = DateRateOverrideBulkCreateRequest(
          roomType: _selectedRoomTypeId!,
          startDate: _selectedDate!,
          endDate: _endDate!,
          rate: double.parse(_rateController.text),
          reason: _reasonController.text.trim(),
          closedToArrival: _closedToArrival,
          closedToDeparture: _closedToDeparture,
          minStay:
              _minStayController.text.isEmpty
                  ? null
                  : int.parse(_minStayController.text),
        );

        await notifier.bulkCreateOverrides(request);

        if (mounted) {
          ref.invalidate(dateRateOverridesProvider);
          final days = _endDate!.difference(_selectedDate!).inDays + 1;
          _showSuccess(
            l10n.dateRateCreatedForDays.replaceAll('{days}', '$days'),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Single create
        final request = DateRateOverrideCreateRequest(
          roomType: _selectedRoomTypeId!,
          date: _selectedDate!,
          rate: double.parse(_rateController.text),
          reason: _reasonController.text.trim(),
          closedToArrival: _closedToArrival,
          closedToDeparture: _closedToDeparture,
          minStay:
              _minStayController.text.isEmpty
                  ? null
                  : int.parse(_minStayController.text),
        );

        await notifier.createOverride(request);

        if (mounted) {
          ref.invalidate(dateRateOverridesProvider);
          _showSuccess(l10n.dateRateCreated);
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      _showError('${l10n.error}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deleteDateRateTitle),
            content: Text(
              '${l10n.confirmDeleteDateRate} ${_selectedDate != null ? dateFormat.format(_selectedDate!) : ''}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteOverride();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteOverride() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(dateRateOverrideNotifierProvider.notifier);
      await notifier.deleteOverride(widget.overrideId!);

      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ref.invalidate(dateRateOverridesProvider);
        _showSuccess(l10n.dateRateDeleted);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showError('${l10n.error}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

/// Date Picker Field widget
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate:
              firstDate ?? DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon:
              value != null
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => onChanged(null),
                  )
                  : const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? dateFormat.format(value!)
              : AppLocalizations.of(context)!.selectDatePlaceholder,
          style: TextStyle(
            color: value != null ? null : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
