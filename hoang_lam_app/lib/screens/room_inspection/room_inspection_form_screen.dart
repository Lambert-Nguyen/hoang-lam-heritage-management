import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/room_inspection.dart';
import '../../providers/room_inspection_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for creating or conducting a room inspection
class RoomInspectionFormScreen extends ConsumerStatefulWidget {
  final int? inspectionId;
  final bool isConductMode;

  const RoomInspectionFormScreen({
    super.key,
    this.inspectionId,
    this.isConductMode = false,
  });

  @override
  ConsumerState<RoomInspectionFormScreen> createState() => _RoomInspectionFormScreenState();
}

class _RoomInspectionFormScreenState extends ConsumerState<RoomInspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Form fields for create mode
  int? _selectedRoomId;
  InspectionType _selectedType = InspectionType.routine;
  DateTime _scheduledDate = DateTime.now();
  int? _selectedTemplateId;

  // Fields for conduct mode
  List<ChecklistItem> _checklistItems = [];
  String _notes = '';
  String _actionRequired = '';
  final List<String> _images = [];

  RoomInspection? _existingInspection;

  @override
  void initState() {
    super.initState();
    if (widget.isConductMode && widget.inspectionId != null) {
      _loadInspection();
    }
  }

  Future<void> _loadInspection() async {
    setState(() => _isLoading = true);
    try {
      final inspection = await ref.read(roomInspectionRepositoryProvider).getInspection(widget.inspectionId!);
      setState(() {
        _existingInspection = inspection;
        _checklistItems = List.from(inspection.checklistItems);
        _notes = inspection.notes;
        _actionRequired = inspection.actionRequired;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isConductMode ? l10n.conductInspection : l10n.createInspection)),
        body: const LoadingIndicator(),
      );
    }

    if (widget.isConductMode) {
      return _buildConductScreen();
    }
    return _buildCreateScreen();
  }

  Widget _buildCreateScreen() {
    final templatesAsync = ref.watch(defaultTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.createNewInspection)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.inspectionInfo, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Padding(
                  padding: AppSpacing.paddingCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room selection
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: context.l10n.roomIdRequired,
                          hintText: context.l10n.enterRoomIdHint,
                          prefixIcon: const Icon(Icons.meeting_room),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty ?? true ? context.l10n.pleaseEnterRoomId : null,
                        onChanged: (v) => _selectedRoomId = int.tryParse(v),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Inspection type
                      Text(context.l10n.inspectionType, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: InspectionType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(type.icon, size: 16, color: isSelected ? Colors.white : type.color),
                                const SizedBox(width: 4),
                                Text(type.localizedName(context.l10n)),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedType = type);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Scheduled date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text(context.l10n.inspectionDateLabel),
                        subtitle: Text(
                          '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Template selection
              Text(context.l10n.inspectionTemplateOptional, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return AppCard(
                      child: Padding(
                        padding: AppSpacing.paddingCard,
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(context.l10n.noDefaultTemplateDesc)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: templates.map((template) {
                      final isSelected = _selectedTemplateId == template.id;
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        onTap: () {
                          setState(() {
                            _selectedTemplateId = isSelected ? null : template.id;
                          });
                        },
                        child: Container(
                          padding: AppSpacing.paddingCard,
                          decoration: BoxDecoration(
                            border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isSelected ? Theme.of(context).primaryColor : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(template.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text(
                                      '${template.items.length} ${context.l10n.checklistItemsSuffix}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (template.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    context.l10n.defaultBadge,
                                    style: TextStyle(color: AppColors.success, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => ErrorDisplay(message: '${context.l10n.error}: $e'),
              ),
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _createInspection,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: Text(_isSubmitting ? context.l10n.creatingText : context.l10n.createInspectionBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConductScreen() {
    if (_existingInspection == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.conductInspection)),
        body: ErrorDisplay(message: context.l10n.inspectionNotFound),
      );
    }

    final inspection = _existingInspection!;
    final passedCount = _checklistItems.where((i) => i.passed == true).length;
    final failedCount = _checklistItems.where((i) => i.passed == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${context.l10n.roomLabel} ${inspection.roomNumber}'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _completeInspection,
            icon: const Icon(Icons.check),
            label: Text(context.l10n.completeBtnLabel),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.l10n.progressCount} ${passedCount + failedCount}/${_checklistItems.length}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _checklistItems.isEmpty
                            ? 0
                            : (passedCount + failedCount) / _checklistItems.length,
                        backgroundColor: AppColors.mutedAccent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('✓ $passedCount', style: const TextStyle(color: AppColors.success)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('✗ $failedCount', style: const TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),

          // Checklist items
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.paddingAll,
              itemCount: _checklistItems.length + 1, // +1 for notes section
              itemBuilder: (context, index) {
                if (index == _checklistItems.length) {
                  return _buildNotesSection();
                }
                return _buildChecklistItemCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItemCard(int index) {
    final l10n = AppLocalizations.of(context)!;
    final checklistItem = _checklistItems[index];
    final isPassed = checklistItem.passed;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checklistItem.item,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        checklistItem.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (checklistItem.critical)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(l10n.importantBadge, style: const TextStyle(fontSize: 10, color: AppColors.error)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateItemStatus(index, true),
                    icon: Icon(Icons.check, color: isPassed == true ? Colors.white : AppColors.success),
                    label: Text(l10n.passBtn, style: TextStyle(color: isPassed == true ? Colors.white : AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isPassed == true ? AppColors.success : null,
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateItemStatus(index, false),
                    icon: Icon(Icons.close, color: isPassed == false ? Colors.white : AppColors.error),
                    label: Text(l10n.failBtn, style: TextStyle(color: isPassed == false ? Colors.white : AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isPassed == false ? AppColors.error : null,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
            if (isPassed == false) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: checklistItem.notes,
                decoration: InputDecoration(
                  labelText: l10n.issueNotes,
                  hintText: l10n.describeIssueHint,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
                onChanged: (value) => _updateItemNotes(index, value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.generalNotes, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _notes,
              decoration: InputDecoration(
                hintText: l10n.enterNotesHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: 16),
            Text(l10n.actionRequiredIfAny, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _actionRequired,
              decoration: InputDecoration(
                hintText: l10n.describeActionRequired,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _actionRequired = value,
            ),
          ],
        ),
      ),
    );
  }

  void _updateItemStatus(int index, bool passed) {
    setState(() {
      final checklistItem = _checklistItems[index];
      _checklistItems[index] = checklistItem.copyWith(passed: passed);
    });
  }

  void _updateItemNotes(int index, String notes) {
    setState(() {
      final checklistItem = _checklistItems[index];
      _checklistItems[index] = checklistItem.copyWith(notes: notes);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _createInspection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseSelectRoomMsg), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final data = RoomInspectionCreate(
        room: _selectedRoomId!,
        inspectionType: _selectedType,
        scheduledDate: '${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}',
        templateId: _selectedTemplateId,
      );
      await ref.read(roomInspectionNotifierProvider.notifier).createInspection(data);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.inspectionCreatedSuccess), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _completeInspection() async {
    // Check critical items
    final uncheckedCritical = _checklistItems.where((i) => i.critical && i.passed == null).toList();
    if (uncheckedCritical.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.uncheckedCriticalItems}: ${uncheckedCritical.length}'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final data = CompleteInspection(
        checklistItems: _checklistItems,
        notes: _notes,
        actionRequired: _actionRequired,
        images: _images,
      );
      await ref.read(roomInspectionNotifierProvider.notifier).completeInspection(
            widget.inspectionId!,
            data,
          );
      if (mounted) {
        context.go('/room-inspections');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.inspectionCompleted), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
