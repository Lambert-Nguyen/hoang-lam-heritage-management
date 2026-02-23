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

/// Rate Plan Form Screen for creating and editing rate plans
class RatePlanFormScreen extends ConsumerStatefulWidget {
  final int? ratePlanId; // null for new rate plan

  const RatePlanFormScreen({super.key, this.ratePlanId});

  @override
  ConsumerState<RatePlanFormScreen> createState() => _RatePlanFormScreenState();
}

class _RatePlanFormScreenState extends ConsumerState<RatePlanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _baseRateController;
  late TextEditingController _minStayController;
  late TextEditingController _maxStayController;
  late TextEditingController _advanceBookingController;
  late TextEditingController _descriptionController;

  int? _selectedRoomTypeId;
  bool _isActive = true;
  bool _includesBreakfast = false;
  CancellationPolicy _cancellationPolicy = CancellationPolicy.flexible;
  DateTime? _validFrom;
  DateTime? _validTo;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool get _isEditing => widget.ratePlanId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameEnController = TextEditingController();
    _baseRateController = TextEditingController();
    _minStayController = TextEditingController(text: '1');
    _maxStayController = TextEditingController();
    _advanceBookingController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _baseRateController.dispose();
    _minStayController.dispose();
    _maxStayController.dispose();
    _advanceBookingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromRatePlan(RatePlan plan) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameController.text = plan.name;
    _nameEnController.text = plan.nameEn ?? '';
    _baseRateController.text = plan.baseRate.toInt().toString();
    _minStayController.text = plan.minStay.toString();
    _maxStayController.text = plan.maxStay?.toString() ?? '';
    _advanceBookingController.text = plan.advanceBookingDays?.toString() ?? '';
    _descriptionController.text = plan.description;

    _selectedRoomTypeId = plan.roomType;
    _isActive = plan.isActive;
    _includesBreakfast = plan.includesBreakfast;
    _cancellationPolicy = plan.cancellationPolicy;
    _validFrom = plan.validFrom;
    _validTo = plan.validTo;
  }

  @override
  Widget build(BuildContext context) {
    final roomTypesAsync = ref.watch(roomTypesProvider);

    // Load existing rate plan for editing
    if (_isEditing) {
      final l10n = AppLocalizations.of(context)!;
      final ratePlanAsync = ref.watch(ratePlanByIdProvider(widget.ratePlanId!));
      return ratePlanAsync.when(
        data: (ratePlan) {
          _initFromRatePlan(ratePlan);
          return _buildForm(roomTypesAsync);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.editRatePlan)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.editRatePlan)),
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
        title: Text(_isEditing ? l10n.editRatePlan : l10n.addRatePlan),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: l10n.deleteRatePlan,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Basic Info Section
            _buildSectionHeader(l10n.basicInfo),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${l10n.ratePlanName} *',
                hintText: l10n.ratePlanHint,
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterRatePlanName;
                }
                return null;
              },
            ),

            AppSpacing.gapVerticalMd,

            // Name English (optional)
            TextFormField(
              controller: _nameEnController,
              decoration: InputDecoration(
                labelText: l10n.englishNameOptional,
                hintText: 'VD: Weekend Rate, Summer Rate...',
                prefixIcon: const Icon(Icons.translate),
              ),
            ),

            AppSpacing.gapVerticalMd,

            // Room Type
            roomTypesAsync.when(
              data: (roomTypes) => DropdownButtonFormField<int>(
                initialValue: _selectedRoomTypeId,
                decoration: InputDecoration(
                  labelText: '${l10n.roomType} *',
                  prefixIcon: const Icon(Icons.meeting_room),
                ),
                items: roomTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type.id,
                        child: Text('${type.name} - ${type.formattedBaseRate}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedRoomTypeId = value),
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

            AppSpacing.gapVerticalMd,

            // Base Rate
            TextFormField(
              controller: _baseRateController,
              decoration: InputDecoration(
                labelText: '${l10n.baseRatePerNight} *',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: l10n.vnd,
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

            // Stay Requirements Section
            _buildSectionHeader(l10n.stayRequirements),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStayController,
                    decoration: InputDecoration(
                      labelText: l10n.minNights,
                      prefixIcon: const Icon(Icons.nights_stay),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxStayController,
                    decoration: InputDecoration(
                      labelText: l10n.maxNights,
                      hintText: l10n.noLimit,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            AppSpacing.gapVerticalMd,

            // Advance Booking Days
            TextFormField(
              controller: _advanceBookingController,
              decoration: InputDecoration(
                labelText: l10n.advanceBookingOptional,
                hintText: l10n.advanceBookingHint,
                prefixIcon: const Icon(Icons.schedule),
              ),
              keyboardType: TextInputType.number,
            ),

            AppSpacing.gapVerticalLg,

            // Cancellation Policy Section
            _buildSectionHeader(l10n.cancellationPolicy),

            DropdownButtonFormField<CancellationPolicy>(
              initialValue: _cancellationPolicy,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.policy)),
              items: CancellationPolicy.values
                  .map(
                    (policy) => DropdownMenuItem(
                      value: policy,
                      child: Text(policy.localizedName(context.l10n)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _cancellationPolicy = value);
                }
              },
            ),

            AppSpacing.gapVerticalLg,

            // Valid Date Range Section
            _buildSectionHeader(l10n.validityPeriod),

            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: l10n.fromDate,
                    value: _validFrom,
                    onChanged: (date) => setState(() => _validFrom = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: l10n.toDate,
                    value: _validTo,
                    onChanged: (date) => setState(() => _validTo = date),
                    firstDate: _validFrom,
                  ),
                ),
              ],
            ),

            AppSpacing.gapVerticalLg,

            // Options Section
            _buildSectionHeader(l10n.optionsSection),

            SwitchListTile(
              title: Text(l10n.includesBreakfast),
              subtitle: Text(l10n.ratePlanIncludesFreeBreakfast),
              value: _includesBreakfast,
              onChanged: (value) => setState(() => _includesBreakfast = value),
              secondary: const Icon(Icons.free_breakfast),
            ),

            SwitchListTile(
              title: Text(l10n.isActive),
              subtitle: Text(l10n.showApplyRatePlan),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: const Icon(Icons.toggle_on),
            ),

            AppSpacing.gapVerticalMd,

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                hintText: l10n.ratePlanNotes,
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),

            AppSpacing.gapVerticalXl,

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveRatePlan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? l10n.update : l10n.createRatePlan),
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

  Future<void> _saveRatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomTypeId == null) return;
    final l10n = context.l10n;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(ratePlanNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.updateRatePlan(widget.ratePlanId!, {
          'name': _nameController.text.trim(),
          'name_en': _nameEnController.text.trim().isEmpty
              ? null
              : _nameEnController.text.trim(),
          'room_type': _selectedRoomTypeId,
          'base_rate': int.parse(_baseRateController.text),
          'is_active': _isActive,
          'min_stay': int.tryParse(_minStayController.text) ?? 1,
          'max_stay': _maxStayController.text.isEmpty
              ? null
              : int.parse(_maxStayController.text),
          'advance_booking_days': _advanceBookingController.text.isEmpty
              ? null
              : int.parse(_advanceBookingController.text),
          'cancellation_policy': _cancellationPolicy.name,
          'valid_from': _validFrom?.toIso8601String().split('T')[0],
          'valid_to': _validTo?.toIso8601String().split('T')[0],
          'includes_breakfast': _includesBreakfast,
          'description': _descriptionController.text.trim(),
        });

        if (mounted) {
          ref.invalidate(ratePlansProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.ratePlanUpdated} "${_nameController.text}"',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final request = RatePlanCreateRequest(
          name: _nameController.text.trim(),
          nameEn: _nameEnController.text.trim().isEmpty
              ? null
              : _nameEnController.text.trim(),
          roomType: _selectedRoomTypeId!,
          baseRate: double.parse(_baseRateController.text),
          isActive: _isActive,
          minStay: int.tryParse(_minStayController.text) ?? 1,
          maxStay: _maxStayController.text.isEmpty
              ? null
              : int.parse(_maxStayController.text),
          advanceBookingDays: _advanceBookingController.text.isEmpty
              ? null
              : int.parse(_advanceBookingController.text),
          cancellationPolicy: _cancellationPolicy,
          validFrom: _validFrom,
          validTo: _validTo,
          includesBreakfast: _includesBreakfast,
          description: _descriptionController.text.trim(),
        );

        await notifier.createRatePlan(request);

        if (mounted) {
          ref.invalidate(ratePlansProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.ratePlanCreated} "${_nameController.text}"',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.deleteRatePlan}?'),
        content: Text(
          '${l10n.confirmDeleteRatePlan} "${_nameController.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRatePlan();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRatePlan() async {
    setState(() => _isLoading = true);
    final l10n = context.l10n;

    try {
      final notifier = ref.read(ratePlanNotifierProvider.notifier);
      await notifier.deleteRatePlan(widget.ratePlanId!);

      if (mounted) {
        ref.invalidate(ratePlansProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.ratePlanDeleted} "${_nameController.text}"'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          firstDate: firstDate ?? DateTime(2020),
          lastDate: DateTime(2030),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
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
