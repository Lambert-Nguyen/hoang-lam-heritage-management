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
  ConsumerState<InspectionTemplateScreen> createState() => _InspectionTemplateScreenState();
}

class _InspectionTemplateScreenState extends ConsumerState<InspectionTemplateScreen> {
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
          Icon(Icons.library_books, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noTemplates,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(template.name, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    if (template.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Mặc định', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(template.inspectionType.icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      template.inspectionType.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    if (template.roomTypeName != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.meeting_room, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        template.roomTypeName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Danh sách kiểm tra (${template.items.length} mục)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...template.items.map((templateItem) => _buildTemplateItemTile(templateItem)),
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
                        label: const Text('Chỉnh sửa'),
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
                        label: const Text('Sao chép'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_box_outline_blank, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(templateItem.item, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  templateItem.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (templateItem.critical)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Quan trọng', style: TextStyle(fontSize: 10, color: Colors.red)),
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
        await ref.read(inspectionTemplateNotifierProvider.notifier).createTemplate(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo mẫu thành công'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _editTemplate(InspectionTemplate template) {
    // TODO: Implement edit template
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng chỉnh sửa đang phát triển')),
    );
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
      await ref.read(inspectionTemplateNotifierProvider.notifier).createTemplate(newTemplate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao chép mẫu thành công'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTemplate(InspectionTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mẫu "${template.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(inspectionTemplateNotifierProvider.notifier).deleteTemplate(template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa mẫu'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
              child: Icon(Icons.library_books, color: template.inspectionType.color),
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (template.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Mặc định', style: TextStyle(color: Colors.green, fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(template.inspectionType.icon, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        template.inspectionType.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.checklist, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${template.items.length} mục',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
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
  ConsumerState<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
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
      const TemplateItem(category: 'Phòng ngủ', item: 'Giường ngủ sạch sẽ', critical: true),
      const TemplateItem(category: 'Phòng ngủ', item: 'Ga trải giường thay mới', critical: true),
      const TemplateItem(category: 'Phòng ngủ', item: 'Gối và chăn sạch', critical: true),
      const TemplateItem(category: 'Phòng tắm', item: 'Nhà vệ sinh sạch', critical: true),
      const TemplateItem(category: 'Phòng tắm', item: 'Khăn tắm đầy đủ', critical: true),
      const TemplateItem(category: 'Phòng tắm', item: 'Đồ dùng vệ sinh đầy đủ', critical: false),
      const TemplateItem(category: 'Tiện nghi', item: 'Điều hòa hoạt động', critical: false),
      const TemplateItem(category: 'Tiện nghi', item: 'TV hoạt động', critical: false),
      const TemplateItem(category: 'Tiện nghi', item: 'Tủ lạnh hoạt động', critical: false),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Tạo mẫu kiểm tra mới', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),

                // Name field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tên mẫu *',
                    hintText: 'VD: Kiểm tra checkout tiêu chuẩn',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tên mẫu' : null,
                  onChanged: (v) => _name = v,
                ),
                const SizedBox(height: 16),

                // Type selection
                Text('Loại kiểm tra', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: InspectionType.values.map((type) {
                    final isSelected = _type == type;
                    return ChoiceChip(
                      label: Text(type.displayName),
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
                  decoration: const InputDecoration(
                    labelText: 'ID Loại phòng (tùy chọn)',
                    hintText: 'VD: 1, 2, 3',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _roomType = int.tryParse(v),
                ),
                const SizedBox(height: 16),

                // Is default
                SwitchListTile(
                  title: const Text('Mẫu mặc định'),
                  subtitle: const Text('Sử dụng mẫu này khi tạo kiểm tra mới'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(height: 24),

                // Items section
                Row(
                  children: [
                    Text('Danh sách kiểm tra (${_items.length})', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm'),
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
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(templateItem.item, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                templateItem.category,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (templateItem.critical)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Quan trọng', style: TextStyle(fontSize: 10, color: Colors.red)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => setState(() => _items.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _submit,
                  child: const Text('Tạo mẫu'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm mục kiểm tra'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(labelText: 'Tên mục *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  value: _itemCategory,
                  items: const [
                    DropdownMenuItem(value: 'Phòng ngủ', child: Text('Phòng ngủ')),
                    DropdownMenuItem(value: 'Phòng tắm', child: Text('Phòng tắm')),
                    DropdownMenuItem(value: 'Tiện nghi', child: Text('Tiện nghi')),
                    DropdownMenuItem(value: 'Điện tử', child: Text('Điện tử')),
                    DropdownMenuItem(value: 'An toàn', child: Text('An toàn')),
                    DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                  ],
                  onChanged: (v) => setDialogState(() => _itemCategory = v ?? 'Phòng ngủ'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Quan trọng'),
                  value: _itemCritical,
                  onChanged: (v) => setDialogState(() => _itemCritical = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              FilledButton(
                onPressed: () {
                  if (_itemNameController.text.isNotEmpty) {
                    setState(() {
                      _items.add(TemplateItem(
                        item: _itemNameController.text,
                        category: _itemCategory,
                        critical: _itemCritical,
                      ));
                    });
                    _itemNameController.clear();
                    _itemCritical = false;
                    Navigator.pop(context);
                  }
                },
                child: const Text('Thêm'),
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
        const SnackBar(content: Text('Vui lòng thêm ít nhất một mục kiểm tra'), backgroundColor: Colors.red),
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
