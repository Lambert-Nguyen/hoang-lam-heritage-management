import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';

/// Screen for creating or editing a guest
class GuestFormScreen extends ConsumerStatefulWidget {
  final Guest? guest;

  const GuestFormScreen({super.key, this.guest});

  @override
  ConsumerState<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends ConsumerState<GuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _idIssuePlaceController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _notesController;
  late final TextEditingController _dateOfBirthController;
  late final TextEditingController _idIssueDateController;

  // Form state
  late IDType _idType;
  late String _nationality;
  late Gender? _gender;
  DateTime? _dateOfBirth;
  DateTime? _idIssueDate;
  late bool _isVip;

  bool get _isEditing => widget.guest != null;

  @override
  void initState() {
    super.initState();
    final guest = widget.guest;

    _fullNameController = TextEditingController(text: guest?.fullName ?? '');
    _phoneController = TextEditingController(text: guest?.phone ?? '');
    _emailController = TextEditingController(text: guest?.email ?? '');
    _idNumberController = TextEditingController(text: guest?.idNumber ?? '');
    _idIssuePlaceController = TextEditingController(
      text: guest?.idIssuePlace ?? '',
    );
    _addressController = TextEditingController(text: guest?.address ?? '');
    _cityController = TextEditingController(text: guest?.city ?? '');
    _notesController = TextEditingController(text: guest?.notes ?? '');

    _dateOfBirthController = TextEditingController(
      text: _formatDateValue(guest?.dateOfBirth),
    );
    _idIssueDateController = TextEditingController(
      text: _formatDateValue(guest?.idIssueDate),
    );

    _idType = guest?.idType ?? IDType.cccd;
    _nationality = guest?.nationality ?? 'Vietnam';
    _gender = guest?.gender;
    _dateOfBirth = guest?.dateOfBirth;
    _idIssueDate = guest?.idIssueDate;
    _isVip = guest?.isVip ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _idIssuePlaceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _dateOfBirthController.dispose();
    _idIssueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? context.l10n.editGuestTitle : context.l10n.addGuest,
        ),
        actions: [
          if (_isEditing)
            AppIconButton(
              icon: _isVip ? Icons.star : Icons.star_border,
              color: _isVip ? AppColors.warning : null,
              onPressed: () => setState(() => _isVip = !_isVip),
              tooltip: _isVip ? context.l10n.removeVip : context.l10n.markVip,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Required information
              _buildSectionHeader(context.l10n.requiredInfo, isRequired: true),
              AppSpacing.gapVerticalSm,
              _buildRequiredSection(),
              AppSpacing.gapVerticalLg,

              // ID information
              _buildSectionHeader(context.l10n.identityDocument),
              AppSpacing.gapVerticalSm,
              _buildIdSection(),
              AppSpacing.gapVerticalLg,

              // Personal information
              _buildSectionHeader(context.l10n.personalInfo),
              AppSpacing.gapVerticalSm,
              _buildPersonalSection(),
              AppSpacing.gapVerticalLg,

              // Address
              _buildSectionHeader(context.l10n.address),
              AppSpacing.gapVerticalSm,
              _buildAddressSection(),
              AppSpacing.gapVerticalLg,

              // Notes
              _buildSectionHeader(context.l10n.internalNotes),
              AppSpacing.gapVerticalSm,
              _buildNotesSection(),
              AppSpacing.gapVerticalXl,
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (isRequired) ...[
          AppSpacing.gapHorizontalXs,
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRequiredSection() {
    return AppCard(
      child: Column(
        children: [
          AppTextField(
            controller: _fullNameController,
            label: context.l10n.fullName,
            prefixIcon: Icons.person,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10n.pleaseEnterFullName;
              }
              if (value.trim().length < 2) {
                return context.l10n.fullNameMinLength;
              }
              return null;
            },
          ),
          AppSpacing.gapVerticalMd,
          PhoneTextField(
            controller: _phoneController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.l10n.pleaseEnterPhone;
              }
              if (value.length < 10 || value.length > 11) {
                return context.l10n.phoneMustBe10;
              }
              if (!value.startsWith('0')) {
                return context.l10n.phoneMustStartWith0;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdSection() {
    return AppCard(
      child: Column(
        children: [
          // ID Type dropdown
          AppDropdown<IDType>(
            label: context.l10n.documentType,
            value: _idType,
            prefixIcon: _idType.icon,
            items:
                IDType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 20),
                            AppSpacing.gapHorizontalSm,
                            Text(type.fullDisplayName),
                          ],
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _idType = value);
              }
            },
          ),
          AppSpacing.gapVerticalMd,

          // ID Number
          AppTextField(
            controller: _idNumberController,
            label: context.l10n.documentNumber,
            prefixIcon: Icons.numbers,
            textInputAction: TextInputAction.next,
            keyboardType:
                _idType == IDType.passport
                    ? TextInputType.text
                    : TextInputType.number,
            inputFormatters: [
              if (_idType != IDType.passport)
                FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                _idType == IDType.passport ? 20 : 12,
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,

          // ID Issue Place
          AppTextField(
            controller: _idIssuePlaceController,
            label: context.l10n.issuedBy,
            prefixIcon: Icons.place,
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapVerticalMd,

          // ID Issue Date
          _buildDateField(
            label: context.l10n.issueDate,
            value: _idIssueDate,
            lastDate: DateTime.now(),
            firstDate: DateTime(1950),
            controller: _idIssueDateController,
            onChanged:
                (date) => setState(() {
                  _idIssueDate = date;
                  _idIssueDateController.text = _formatDateValue(date);
                }),
            onClear:
                () => setState(() {
                  _idIssueDate = null;
                  _idIssueDateController.text = '';
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return AppCard(
      child: Column(
        children: [
          // Email
          AppTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final emailRegex = RegExp(
                  r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,63}$',
                );
                if (!emailRegex.hasMatch(value)) {
                  return context.l10n.invalidEmail;
                }
              }
              return null;
            },
          ),
          AppSpacing.gapVerticalMd,

          // Nationality dropdown (task 1.6.8)
          NationalityDropdown(
            value: _nationality,
            onChanged: (value) {
              if (value != null) {
                setState(() => _nationality = value);
              }
            },
          ),
          AppSpacing.gapVerticalMd,

          // Gender dropdown
          AppDropdown<Gender?>(
            label: context.l10n.gender,
            value: _gender,
            prefixIcon: _gender?.icon ?? Icons.person,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(context.l10n.notSpecified),
              ),
              ...Gender.values.map(
                (gender) => DropdownMenuItem(
                  value: gender,
                  child: Row(
                    children: [
                      Icon(gender.icon, size: 20),
                      AppSpacing.gapHorizontalSm,
                      Text(gender.localizedName(context.l10n)),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _gender = value),
          ),
          AppSpacing.gapVerticalMd,

          // Date of birth
          _buildDateField(
            label: context.l10n.dateOfBirth,
            value: _dateOfBirth,
            lastDate: DateTime.now(),
            firstDate: DateTime(1920),
            controller: _dateOfBirthController,
            onChanged:
                (date) => setState(() {
                  _dateOfBirth = date;
                  _dateOfBirthController.text = _formatDateValue(date);
                }),
            onClear:
                () => setState(() {
                  _dateOfBirth = null;
                  _dateOfBirthController.text = '';
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return AppCard(
      child: Column(
        children: [
          AppTextField(
            controller: _addressController,
            label: context.l10n.address,
            prefixIcon: Icons.location_on,
            textInputAction: TextInputAction.next,
            maxLines: 2,
          ),
          AppSpacing.gapVerticalMd,
          AppTextField(
            controller: _cityController,
            label: context.l10n.city,
            prefixIcon: Icons.location_city,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return AppCard(
      child: AppTextField(
        controller: _notesController,
        label: context.l10n.internalNotes,
        prefixIcon: Icons.note,
        maxLines: 3,
        hint: context.l10n.preferencesHint,
      ),
    );
  }

  static String _formatDateValue(DateTime? value) {
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required DateTime firstDate,
    required DateTime lastDate,
    required TextEditingController controller,
    required ValueChanged<DateTime> onChanged,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    value ??
                    DateTime.now().subtract(const Duration(days: 365 * 30)),
                firstDate: firstDate,
                lastDate: lastDate,
                locale: const Locale('vi'),
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: IgnorePointer(
              child: AppTextField(
                label: label,
                hint: 'dd/mm/yyyy',
                controller: controller,
                prefixIcon: Icons.calendar_today,
              ),
            ),
          ),
        ),
        if (value != null && onClear != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: onClear,
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.l10n.cancel,
                isOutlined: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              flex: 2,
              child: AppButton(
                label:
                    _isEditing
                        ? context.l10n.saveChanges
                        : context.l10n.addGuest,
                icon: _isEditing ? Icons.save : Icons.person_add,
                isLoading: _isLoading,
                onPressed: _submitForm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final guest = Guest(
        id: widget.guest?.id ?? 0,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        idType: _idType,
        idNumber:
            _idNumberController.text.trim().isEmpty
                ? null
                : _idNumberController.text.trim(),
        idIssueDate: _idIssueDate,
        idIssuePlace: _idIssuePlaceController.text.trim(),
        nationality: _nationality,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _nationality == 'Vietnam' ? 'Vietnam' : '',
        isVip: _isVip,
        notes: _notesController.text.trim(),
      );

      Guest? result;
      if (_isEditing) {
        result = await ref.read(guestStateProvider.notifier).updateGuest(guest);
      } else {
        result = await ref.read(guestStateProvider.notifier).createGuest(guest);
      }

      // Invalidate guest providers so lists refresh
      ref.invalidate(guestsProvider);

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? context.l10n.guestInfoUpdated
                  : context.l10n.newGuestAdded,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, result);
      } else {
        // Show error if result is null but no exception was thrown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.error}: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Nationality dropdown widget (task 1.6.8)
class NationalityDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final String? label;

  const NationalityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<NationalityDropdown> createState() => _NationalityDropdownState();
}

class _NationalityDropdownState extends State<NationalityDropdown> {
  String? _customNationality;
  bool _showCustomInput = false;
  late final TextEditingController _customNationalityController;

  @override
  void initState() {
    super.initState();
    if (!Nationalities.common.contains(widget.value)) {
      _customNationality = widget.value;
      _showCustomInput = true;
    }
    _customNationalityController = TextEditingController(
      text: _customNationality ?? '',
    );
  }

  @override
  void dispose() {
    _customNationalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustomInput) {
      return Row(
        children: [
          Expanded(
            child: AppTextField(
              label: widget.label ?? context.l10n.nationality,
              controller: _customNationalityController,
              prefixIcon: Icons.flag,
              onChanged: (value) {
                _customNationality = value;
                widget.onChanged(value);
              },
            ),
          ),
          AppSpacing.gapHorizontalSm,
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              setState(() {
                _showCustomInput = false;
                widget.onChanged('Vietnam');
              });
            },
            tooltip: context.l10n.selectFromList,
          ),
        ],
      );
    }

    return AppDropdown<String>(
      label: widget.label ?? context.l10n.nationality,
      value:
          Nationalities.common.contains(widget.value) ? widget.value : 'Other',
      prefixIcon: Icons.flag,
      items: [
        ...Nationalities.common.map(
          (nat) => DropdownMenuItem(
            value: nat,
            child: Text(Nationalities.getDisplayName(nat)),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == 'Other') {
          setState(() {
            _showCustomInput = true;
            _customNationality = '';
          });
          widget.onChanged('');
        } else {
          widget.onChanged(value);
        }
      },
    );
  }
}
