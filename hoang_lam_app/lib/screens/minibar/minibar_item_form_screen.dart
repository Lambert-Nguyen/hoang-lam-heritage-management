import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/minibar.dart';
import '../../providers/minibar_provider.dart';
import '../../widgets/common/loading_indicator.dart';

/// Form screen for creating/editing minibar items
class MinibarItemFormScreen extends ConsumerStatefulWidget {
  final MinibarItem? item;

  const MinibarItemFormScreen({super.key, this.item});

  @override
  ConsumerState<MinibarItemFormScreen> createState() =>
      _MinibarItemFormScreenState();
}

class _MinibarItemFormScreenState extends ConsumerState<MinibarItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  TextEditingController? _autocompleteController;
  VoidCallback? _autocompleteSyncListener;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.item!.name;
      _categoryController.text = widget.item!.category;
      _costController.text = widget.item!.cost.toStringAsFixed(0);
      _priceController.text = widget.item!.price.toStringAsFixed(0);
      _isActive = widget.item!.isActive;
    } else {
      _costController.text = '0';
    }
  }

  @override
  void dispose() {
    _removeAutocompleteListener();
    _nameController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _removeAutocompleteListener() {
    if (_autocompleteController != null && _autocompleteSyncListener != null) {
      _autocompleteController!.removeListener(_autocompleteSyncListener!);
    }
    _autocompleteController = null;
    _autocompleteSyncListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(minibarCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editProduct : l10n.addProduct),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: l10n.deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '${l10n.name} *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.local_bar),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterProductName;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.gapVerticalMd,

                  // Category dropdown
                  categoriesAsync.when(
                    data: (categories) => Autocomplete<String>(
                      initialValue: TextEditingValue(
                        text: _categoryController.text,
                      ),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return categories;
                        }
                        return categories.where((c) => c
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) {
                        _categoryController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode,
                          onFieldSubmitted) {
                        // Sync with our controller, avoiding listener accumulation
                        if (_autocompleteController != controller) {
                          _removeAutocompleteListener();
                          _autocompleteController = controller;
                          controller.text = _categoryController.text;
                          _autocompleteSyncListener = () {
                            _categoryController.text = controller.text;
                          };
                          controller.addListener(_autocompleteSyncListener!);
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n.category,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.category),
                            hintText: l10n.enterOrSelectCategory,
                          ),
                        );
                      },
                    ),
                    loading: () => TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                      ),
                    ),
                    error: (_, __) => TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Price fields row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costController,
                          decoration: InputDecoration(
                            labelText: l10n.costPrice,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.attach_money),
                            suffixText: '₫',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      AppSpacing.gapHorizontalMd,
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: '${l10n.sellingPrice} *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.sell),
                            suffixText: '₫',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.requiredField;
                            }
                            if (double.tryParse(value) == null) {
                              return l10n.invalid;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalMd,

                  // Active switch
                  SwitchListTile(
                    title: Text(l10n.activeLabel),
                    subtitle: Text(_isActive ? l10n.activeSelling : l10n.inactiveSelling),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    secondary: Icon(
                      _isActive ? Icons.check_circle : Icons.cancel,
                      color: _isActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                  AppSpacing.gapVerticalLg,

                  // Profit margin display
                  if (_costController.text.isNotEmpty &&
                      _priceController.text.isNotEmpty)
                    _buildProfitMarginCard(),

                  AppSpacing.gapVerticalLg,

                  // Submit button
                  FilledButton(
                    onPressed: _submitForm,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(_isEditing ? l10n.updateLabel : l10n.addProduct),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfitMarginCard() {
    final l10n = context.l10n;
    final costPrice = double.tryParse(_costController.text) ?? 0;
    final sellingPrice = double.tryParse(_priceController.text) ?? 0;
    final profit = sellingPrice - costPrice;
    final margin = costPrice > 0 ? (profit / costPrice * 100) : 0;

    return Card(
      color: profit >= 0
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildProfitItem(
              l10n.profitLabel,
              '${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(0)}₫',
              profit >= 0 ? AppColors.success : AppColors.error,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            _buildProfitItem(
              l10n.profitMargin,
              '${margin.toStringAsFixed(1)}%',
              profit >= 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final request = UpdateMinibarItemRequest(
          name: _nameController.text,
          category: _categoryController.text.isEmpty
              ? null
              : _categoryController.text,
          cost: double.tryParse(_costController.text) ?? 0,
          price: double.tryParse(_priceController.text),
          isActive: _isActive,
        );
        await ref
            .read(minibarProvider.notifier)
            .updateItem(widget.item!.id, request);
      } else {
        final request = CreateMinibarItemRequest(
          name: _nameController.text,
          category: _categoryController.text.isEmpty
              ? ''
              : _categoryController.text,
          cost: double.tryParse(_costController.text) ?? 0,
          price: double.parse(_priceController.text),
          isActive: _isActive,
        );
        await ref.read(minibarProvider.notifier).createItem(request);
      }

      ref.invalidate(minibarItemsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? l10n.productUpdatedSuccess
                : l10n.productAddedMsg),
            backgroundColor: AppColors.success,
          ),
        );
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

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteProduct),
        content: Text('${l10n.confirmDeleteProductMsg} "${widget.item!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(minibarProvider.notifier)
          .deleteItem(widget.item!.id);
      ref.invalidate(minibarItemsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productDeletedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
