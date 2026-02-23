import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/room_inspection.dart';
import '../../providers/room_inspection_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen for managing inspection templates
class InspectionTemplateScreen extends ConsumerStatefulWidget {
  const InspectionTemplateScreen({super.key});

  @override
  ConsumerState<InspectionTemplateScreen> createState() =>
      _InspectionTemplateScreenState();
}

class _InspectionTemplateScreenState
    extends ConsumerState<InspectionTemplateScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(inspectionTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inspectionTemplate)),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(inspectionTemplatesProvider),
            child: ListView.builder(
              padding: AppSpacing.paddingAll,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateCard(
                  template: template,
                  onTap: () => _showTemplateDetail(template),
                  onDelete: () => _deleteTemplate(template),
                );
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(
          message: '${l10n.error}: $e',
          onRetry: () => ref.invalidate(inspectionTemplatesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTemplateDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.createTemplate),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noTemplates,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _showCreateTemplateDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.createFirstTemplate),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetail(InspectionTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          final l10n = context.l10n;
          return Container(
            padding: AppSpacing.paddingAll,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.mutedAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (template.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.defaultBadge,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      template.inspectionType.icon,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      template.inspectionType.localizedName(context.l10n),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (template.roomTypeName != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.meeting_room,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        template.roomTypeName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  '${l10n.checklistCount} (${template.items.length} ${l10n.itemsSuffix})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...template.items.map(
                  (templateItem) => _buildTemplateItemTile(templateItem),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editTemplate(template);
                        },
                        icon: const Icon(Icons.edit),
                        label: Text(l10n.editLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _duplicateTemplate(template);
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(l10n.duplicateBtn),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateItemTile(TemplateItem templateItem) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mutedAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.mutedAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  templateItem.item,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  templateItem.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (templateItem.critical)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.critical,
                style: const TextStyle(fontSize: 10, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateTemplateDialog() async {
    final result = await showModalBottomSheet<InspectionTemplateCreate>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateTemplateSheet(),
    );

    if (result != null) {
      try {
        await ref
            .read(inspectionTemplateNotifierProvider.notifier)
            .createTemplate(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.templateCreatedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.l10n.error}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _editTemplate(InspectionTemplate template) {
    // TODO: Implement edit template
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.editFeatureInProgress)));
  }

  Future<void> _duplicateTemplate(InspectionTemplate template) async {
    try {
      final newTemplate = InspectionTemplateCreate(
        name: '${template.name} (Copy)',
        inspectionType: template.inspectionType,
        roomType: template.roomType,
        isDefault: false,
        items: template.items,
      );
      await ref
          .read(inspectionTemplateNotifierProvider.notifier)
          .createTemplate(newTemplate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.templateDuplicated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTemplate(InspectionTemplate template) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteTemplate),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(inspectionTemplateNotifierProvider.notifier)
            .deleteTemplate(template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.templateDeletedSuccess),
              backgroundColor: AppColors.success,
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
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final InspectionTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: template.inspectionType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.library_books,
                color: template.inspectionType.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (template.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.defaultBadge,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        template.inspectionType.icon,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        template.inspectionType.localizedName(context.l10n),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.checklist,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${template.items.length} ${l10n.itemsSuffix}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTemplateSheet extends ConsumerStatefulWidget {
  const _CreateTemplateSheet();

  @override
  ConsumerState<_CreateTemplateSheet> createState() =>
      _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends ConsumerState<_CreateTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  InspectionType _type = InspectionType.routine;
  int? _roomType;
  bool _isDefault = false;
  List<TemplateItem> _items = [];

  final _itemNameController = TextEditingController();
  String _itemCategory = 'Phòng ngủ';
  bool _itemCritical = false;

  @override
  void initState() {
    super.initState();
    // Add some default items
    _items = [
      const TemplateItem(
        category: 'Phòng ngủ',
        item: 'Giường ngủ sạch sẽ',
        critical: true,
      ),
      const TemplateItem(
        category: 'Phòng ngủ',
        item: 'Ga trải giường thay mới',
        critical: true,
      ),
      const TemplateItem(
        category: 'Phòng ngủ',
        item: 'Gối và chăn sạch',
        critical: true,
      ),
      const TemplateItem(
        category: 'Phòng tắm',
        item: 'Nhà vệ sinh sạch',
        critical: true,
      ),
      const TemplateItem(
        category: 'Phòng tắm',
        item: 'Khăn tắm đầy đủ',
        critical: true,
      ),
      const TemplateItem(
        category: 'Phòng tắm',
        item: 'Đồ dùng vệ sinh đầy đủ',
        critical: false,
      ),
      const TemplateItem(
        category: 'Tiện nghi',
        item: 'Điều hòa hoạt động',
        critical: false,
      ),
      const TemplateItem(
        category: 'Tiện nghi',
        item: 'TV hoạt động',
        critical: false,
      ),
      const TemplateItem(
        category: 'Tiện nghi',
        item: 'Tủ lạnh hoạt động',
        critical: false,
      ),
    ];
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        final l10n = context.l10n;
        return Container(
          padding: AppSpacing.paddingAll,
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.mutedAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.createNewTemplateTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '${l10n.templateNameLabel} *',
                    hintText: l10n.templateNameHint,
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? l10n.pleaseEnterTemplateName : null,
                  onChanged: (v) => _name = v,
                ),
                const SizedBox(height: 16),

                // Type selection
                Text(
                  l10n.inspectionTypeLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: InspectionType.values.map((type) {
                    final isSelected = _type == type;
                    return ChoiceChip(
                      label: Text(type.localizedName(context.l10n)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _type = type);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Room type (as numeric ID)
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.roomTypeIdOptional,
                    hintText: l10n.roomTypeIdHint,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _roomType = int.tryParse(v),
                ),
                const SizedBox(height: 16),

                // Is default
                SwitchListTile(
                  title: Text(l10n.defaultTemplateLabel),
                  subtitle: Text(l10n.defaultTemplateHint),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(height: 24),

                // Items section
                Row(
                  children: [
                    Text(
                      '${l10n.checklistCount} (${_items.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final templateItem = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mutedAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.mutedAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                templateItem.item,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                templateItem.category,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (templateItem.critical)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.critical,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () =>
                              setState(() => _items.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.createTemplateBtn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddItemDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.addChecklistItemTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _itemNameController,
                  decoration: InputDecoration(labelText: l10n.itemNameLabel),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: l10n.categoryLabel),
                  initialValue: _itemCategory,
                  items: [
                    DropdownMenuItem(
                      value: 'Phòng ngủ',
                      child: Text(l10n.bedroomCategory),
                    ),
                    DropdownMenuItem(
                      value: 'Phòng tắm',
                      child: Text(l10n.bathroomCategory),
                    ),
                    DropdownMenuItem(
                      value: 'Tiện nghi',
                      child: Text(l10n.amenitiesCategory),
                    ),
                    DropdownMenuItem(
                      value: 'Điện tử',
                      child: Text(l10n.electronicsCategory),
                    ),
                    DropdownMenuItem(
                      value: 'An toàn',
                      child: Text(l10n.safetyCategory),
                    ),
                    DropdownMenuItem(
                      value: 'Khác',
                      child: Text(l10n.otherCategory),
                    ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => _itemCategory = v ?? 'Phòng ngủ'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: Text(l10n.critical),
                  value: _itemCritical,
                  onChanged: (v) =>
                      setDialogState(() => _itemCritical = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (_itemNameController.text.isNotEmpty) {
                    setState(() {
                      _items.add(
                        TemplateItem(
                          item: _itemNameController.text,
                          category: _itemCategory,
                          critical: _itemCritical,
                        ),
                      );
                    });
                    _itemNameController.clear();
                    _itemCritical = false;
                    Navigator.pop(context);
                  }
                },
                child: Text(l10n.addLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseAddAtLeastOne),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      InspectionTemplateCreate(
        name: _name,
        inspectionType: _type,
        roomType: _roomType,
        isDefault: _isDefault,
        items: _items,
      ),
    );
  }
}
