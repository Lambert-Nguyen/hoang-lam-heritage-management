import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/guest.dart';
import '../../providers/guest_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';

/// Screen for creating or editing a guest
class GuestFormScreen extends ConsumerStatefulWidget {
  final Guest? guest;

  const GuestFormScreen({
    super.key,
    this.guest,
  });

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
    _idIssuePlaceController =
        TextEditingController(text: guest?.idIssuePlace ?? '');
    _addressController = TextEditingController(text: guest?.address ?? '');
    _cityController = TextEditingController(text: guest?.city ?? '');
    _notesController = TextEditingController(text: guest?.notes ?? '');

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa khách hàng' : 'Thêm khách hàng'),
        actions: [
          if (_isEditing)
            AppIconButton(
              icon: _isVip ? Icons.star : Icons.star_border,
              color: _isVip ? AppColors.warning : null,
              onPressed: () => setState(() => _isVip = !_isVip),
              tooltip: _isVip ? 'Bỏ VIP' : 'Đánh dấu VIP',
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
              _buildSectionHeader('Thông tin bắt buộc', isRequired: true),
              AppSpacing.gapVerticalSm,
              _buildRequiredSection(),
              AppSpacing.gapVerticalLg,

              // ID information
              _buildSectionHeader('Giấy tờ tùy thân'),
              AppSpacing.gapVerticalSm,
              _buildIdSection(),
              AppSpacing.gapVerticalLg,

              // Personal information
              _buildSectionHeader('Thông tin cá nhân'),
              AppSpacing.gapVerticalSm,
              _buildPersonalSection(),
              AppSpacing.gapVerticalLg,

              // Address
              _buildSectionHeader('Địa chỉ'),
              AppSpacing.gapVerticalSm,
              _buildAddressSection(),
              AppSpacing.gapVerticalLg,

              // Notes
              _buildSectionHeader('Ghi chú'),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (isRequired) ...[
          AppSpacing.gapHorizontalXs,
          const Text(
            '*',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
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
            label: 'Họ và tên',
            prefixIcon: Icons.person,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập họ và tên';
              }
              if (value.trim().length < 2) {
                return 'Họ và tên phải có ít nhất 2 ký tự';
              }
              return null;
            },
          ),
          AppSpacing.gapVerticalMd,
          PhoneTextField(
            controller: _phoneController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số điện thoại';
              }
              if (value.length != 10) {
                return 'Số điện thoại phải có 10 số';
              }
              if (!value.startsWith('0')) {
                return 'Số điện thoại phải bắt đầu bằng 0';
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
            label: 'Loại giấy tờ',
            value: _idType,
            prefixIcon: _idType.icon,
            items: IDType.values
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
            label: 'Số giấy tờ',
            prefixIcon: Icons.numbers,
            textInputAction: TextInputAction.next,
            keyboardType: _idType == IDType.passport
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
            label: 'Nơi cấp',
            prefixIcon: Icons.place,
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.gapVerticalMd,

          // ID Issue Date
          _buildDateField(
            label: 'Ngày cấp',
            value: _idIssueDate,
            lastDate: DateTime.now(),
            firstDate: DateTime(1950),
            onChanged: (date) => setState(() => _idIssueDate = date),
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
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Email không hợp lệ';
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
            label: 'Giới tính',
            value: _gender,
            prefixIcon: _gender?.icon ?? Icons.person,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Không xác định'),
              ),
              ...Gender.values.map(
                (gender) => DropdownMenuItem(
                  value: gender,
                  child: Row(
                    children: [
                      Icon(gender.icon, size: 20),
                      AppSpacing.gapHorizontalSm,
                      Text(gender.displayName),
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
            label: 'Ngày sinh',
            value: _dateOfBirth,
            lastDate: DateTime.now(),
            firstDate: DateTime(1920),
            onChanged: (date) => setState(() => _dateOfBirth = date),
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
            label: 'Địa chỉ',
            prefixIcon: Icons.location_on,
            textInputAction: TextInputAction.next,
            maxLines: 2,
          ),
          AppSpacing.gapVerticalMd,
          AppTextField(
            controller: _cityController,
            label: 'Thành phố',
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
        label: 'Ghi chú',
        prefixIcon: Icons.note,
        maxLines: 3,
        hint: 'Sở thích, yêu cầu đặc biệt...',
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onChanged,
  }) {
    final displayValue = value != null
        ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
        : '';

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
          firstDate: firstDate,
          lastDate: lastDate,
          locale: const Locale('vi'),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: AbsorbPointer(
        child: AppTextField(
          label: label,
          hint: 'dd/mm/yyyy',
          controller: TextEditingController(text: displayValue),
          prefixIcon: Icons.calendar_today,
          suffix: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    if (label == 'Ngày sinh') {
                      setState(() => _dateOfBirth = null);
                    } else {
                      setState(() => _idIssueDate = null);
                    }
                  },
                )
              : null,
        ),
      ),
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
                label: 'Hủy',
                isOutlined: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              flex: 2,
              child: AppButton(
                label: _isEditing ? 'Lưu thay đổi' : 'Thêm khách hàng',
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
        idNumber: _idNumberController.text.trim().isEmpty
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

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Đã cập nhật thông tin khách hàng'
                  : 'Đã thêm khách hàng mới',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
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

  @override
  void initState() {
    super.initState();
    if (!Nationalities.common.contains(widget.value)) {
      _customNationality = widget.value;
      _showCustomInput = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustomInput) {
      return Row(
        children: [
          Expanded(
            child: AppTextField(
              label: widget.label ?? 'Quốc tịch',
              controller: TextEditingController(text: _customNationality),
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
            tooltip: 'Chọn từ danh sách',
          ),
        ],
      );
    }

    return AppDropdown<String>(
      label: widget.label ?? 'Quốc tịch',
      value: Nationalities.common.contains(widget.value) ? widget.value : 'Other',
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
