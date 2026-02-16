import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/housekeeping.dart';
import '../../models/room.dart';
import '../../providers/housekeeping_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';

/// Screen for creating or editing a maintenance request
class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final MaintenanceRequest? request;

  const MaintenanceFormScreen({
    super.key,
    this.request,
  });

  bool get isEditing => request != null;

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedCostController = TextEditingController();

  late int? _selectedRoomId;
  late MaintenanceCategory _selectedCategory;
  late MaintenancePriority _selectedPriority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.request?.room;
    _selectedCategory = widget.request?.category ?? MaintenanceCategory.other;
    _selectedPriority = widget.request?.priority ?? MaintenancePriority.medium;
    _titleController.text = widget.request?.title ?? '';
    _descriptionController.text = widget.request?.description ?? '';
    if (widget.request?.estimatedCost != null) {
      _estimatedCostController.text =
          widget.request!.estimatedCost!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editRequest : l10n.createMaintenanceRequest),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.room,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    roomsAsync.when(
                      data: (rooms) => _buildRoomDropdown(rooms),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => Text(
                        l10n.cannotLoadRoomList,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Title
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _titleController,
                      hint: l10n.describeIssueBriefly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterTitle;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Category selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    _buildCategorySelector(),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Priority selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.priorityLevel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    _buildPrioritySelector(),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Description
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.detailedDescription,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _descriptionController,
                      hint: l10n.describeIssueInDetail,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterDescription;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,

              // Estimated cost (optional)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.estimatedCostOptional,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    AppTextField(
                      controller: _estimatedCostController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                      helper: l10n.vnd,
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalLg,

              // Submit button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: widget.isEditing ? l10n.update : l10n.createRequest,
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRoomDropdown(List<Room> rooms) {
    final l10n = AppLocalizations.of(context)!;
    return AppDropdown<int>(
      value: _selectedRoomId,
      items: rooms
          .map((room) => DropdownMenuItem(
                value: room.id,
                child: Text('${l10n.room} ${room.number}'),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRoomId = value;
        });
      },
      hint: l10n.selectRoom,
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MaintenanceCategory.values.map((category) {
        final isSelected = category == _selectedCategory;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category.color : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 18,
                  color:
                      isSelected ? category.color : AppColors.textSecondary,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  category.localizedName(context.l10n),
                  style: TextStyle(
                    color:
                        isSelected ? category.color : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: MaintenancePriority.values.map((priority) {
        final isSelected = priority == _selectedPriority;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: priority != MaintenancePriority.values.last
                  ? AppSpacing.sm
                  : 0,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? priority.color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? priority.color : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      priority.icon,
                      size: 24,
                      color: isSelected
                          ? priority.color
                          : AppColors.textSecondary,
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      priority.localizedName(context.l10n),
                      style: TextStyle(
                        color: isSelected
                            ? priority.color
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectRoom)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(housekeepingNotifierProvider.notifier);
      
      int? estimatedCost;
      if (_estimatedCostController.text.isNotEmpty) {
        estimatedCost = int.tryParse(_estimatedCostController.text);
      }

      MaintenanceRequest? result;
      if (widget.isEditing) {
        result = await notifier.updateMaintenanceRequest(
          widget.request!.id,
          MaintenanceRequestUpdate(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory.apiValue,
            priority: _selectedPriority.apiValue,
            estimatedCost: estimatedCost,
          ),
        );
      } else {
        result = await notifier.createMaintenanceRequest(
          MaintenanceRequestCreate(
            room: _selectedRoomId!,
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory.apiValue,
            priority: _selectedPriority.apiValue,
          ),
        );
      }

      if (result != null && mounted) {
        // Invalidate maintenance providers so lists refresh
        ref.invalidate(maintenanceRequestsProvider);

        Navigator.pop(context, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? l10n.requestUpdated
                  : l10n.newMaintenanceRequestCreated,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
