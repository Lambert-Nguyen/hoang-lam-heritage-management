import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lost_found.dart';
import '../../providers/lost_found_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Form screen for creating/editing lost & found items
class LostFoundFormScreen extends ConsumerStatefulWidget {
  final int? itemId;
  const LostFoundFormScreen({super.key, this.itemId});
  bool get isEditing => itemId != null;

  @override
  ConsumerState<LostFoundFormScreen> createState() =>
      _LostFoundFormScreenState();
}

class _LostFoundFormScreenState extends ConsumerState<LostFoundFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _foundLocationController;
  late TextEditingController _storageLocationController;
  late TextEditingController _estimatedValueController;
  late TextEditingController _notesController;
  late TextEditingController _contactNotesController;

  LostFoundCategory _selectedCategory = LostFoundCategory.other;
  DateTime _foundDate = DateTime.now();
  bool _guestContacted = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _foundLocationController = TextEditingController();
    _storageLocationController = TextEditingController();
    _estimatedValueController = TextEditingController();
    _notesController = TextEditingController();
    _contactNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _foundLocationController.dispose();
    _storageLocationController.dispose();
    _estimatedValueController.dispose();
    _notesController.dispose();
    _contactNotesController.dispose();
    super.dispose();
  }

  void _initializeFromItem(LostFoundItem item) {
    if (_isInitialized) return;
    _isInitialized = true;
    _itemNameController.text = item.itemName;
    _descriptionController.text = item.description;
    _foundLocationController.text = item.foundLocation;
    _storageLocationController.text = item.storageLocation;
    _estimatedValueController.text =
        item.estimatedValue?.toStringAsFixed(0) ?? '';
    _notesController.text = item.notes;
    _contactNotesController.text = item.contactNotes;
    _selectedCategory = item.category;
    _guestContacted = item.guestContacted;
    try {
      _foundDate = DateTime.parse(item.foundDate);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isEditing) {
      final itemAsync = ref.watch(lostFoundItemByIdProvider(widget.itemId!));
      return Scaffold(
        appBar: AppBar(title: Text(l10n.edit)),
        body: itemAsync.when(
          data: (item) {
            _initializeFromItem(item);
            return _buildForm();
          },
          loading: () => const LoadingIndicator(),
          error:
              (e, _) => ErrorDisplay(
                message: '${l10n.error}: $e',
                onRetry:
                    () => ref.invalidate(
                      lostFoundItemByIdProvider(widget.itemId!),
                    ),
              ),
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: Text(l10n.add)), body: _buildForm());
  }

  Widget _buildForm() {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: l10n.basicInfo),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _itemNameController,
                      label: l10n.itemNameLabel,
                      hint: l10n.itemNameHint,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.pleaseEnterName
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _descriptionController,
                      label: l10n.description,
                      hint: l10n.describeIssueHint,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<LostFoundCategory>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                      ),
                      items:
                          LostFoundCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Icon(c.icon, size: 20, color: c.color),
                                      const SizedBox(width: 8),
                                      Text(c.localizedName(context.l10n)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.foundDateLabel,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_foundDate.day}/${_foundDate.month}/${_foundDate.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: l10n.locationSection),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _foundLocationController,
                      label: l10n.foundLocationLabel,
                      hint: l10n.foundLocationHint,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.pleaseEnterValue
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _storageLocationController,
                      label: l10n.storageLocationLabel,
                      hint: l10n.storageLocationHint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: l10n.contactSection),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.guestContacted),
                      value: _guestContacted,
                      onChanged: (v) => setState(() => _guestContacted = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_guestContacted)
                      AppTextField(
                        controller: _contactNotesController,
                        label: l10n.contactNotes,
                        maxLines: 2,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: l10n.additionalInfo),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _estimatedValueController,
                      label: l10n.estimatedValueVnd,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _notesController,
                      label: l10n.notes,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: widget.isEditing ? l10n.update : l10n.addNew,
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                icon: widget.isEditing ? Icons.save : Icons.add,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _foundDate = picked);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(lostFoundNotifierProvider.notifier);
      final estimatedValue = double.tryParse(_estimatedValueController.text);

      if (widget.isEditing) {
        final update = LostFoundItemUpdate(
          itemName: _itemNameController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          foundLocation: _foundLocationController.text,
          storageLocation: _storageLocationController.text,
          guestContacted: _guestContacted,
          contactNotes: _contactNotesController.text,
          estimatedValue: estimatedValue,
          notes: _notesController.text,
        );
        final result = await notifier.updateItem(widget.itemId!, update);
        if (result != null && mounted) {
          final l10n = context.l10n;
          ref.invalidate(lostFoundItemsProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.itemUpdated)));
          context.pop();
        }
      } else {
        final create = LostFoundItemCreate(
          itemName: _itemNameController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          foundLocation: _foundLocationController.text,
          storageLocation: _storageLocationController.text,
          foundDate: _foundDate.toIso8601String().split('T')[0],
          guestContacted: _guestContacted,
          contactNotes: _contactNotesController.text,
          estimatedValue: estimatedValue,
          notes: _notesController.text,
        );
        final result = await notifier.createItem(create);
        if (result != null && mounted) {
          final l10n = context.l10n;
          ref.invalidate(lostFoundItemsProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.itemCreated)));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
