import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
      final ratePlanAsync = ref.watch(ratePlanByIdProvider(widget.ratePlanId!));
      return ratePlanAsync.when(
        data: (ratePlan) {
          _initFromRatePlan(ratePlan);
          return _buildForm(roomTypesAsync);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Sửa gói giá')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Sửa gói giá')),
          body: Center(child: Text('Lỗi: $error')),
        ),
      );
    }

    return _buildForm(roomTypesAsync);
  }

  Widget _buildForm(AsyncValue<List<RoomType>> roomTypesAsync) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa gói giá' : 'Thêm gói giá'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Xóa gói giá',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Basic Info Section
            _buildSectionHeader('Thông tin cơ bản'),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên gói giá *',
                hintText: 'VD: Giá cuối tuần, Giá mùa hè...',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên gói giá';
                }
                return null;
              },
            ),

            AppSpacing.gapVerticalMd,

            // Name English (optional)
            TextFormField(
              controller: _nameEnController,
              decoration: const InputDecoration(
                labelText: 'Tên tiếng Anh (tùy chọn)',
                hintText: 'VD: Weekend Rate, Summer Rate...',
                prefixIcon: Icon(Icons.translate),
              ),
            ),

            AppSpacing.gapVerticalMd,

            // Room Type
            roomTypesAsync.when(
              data: (roomTypes) => DropdownButtonFormField<int>(
                value: _selectedRoomTypeId,
                decoration: const InputDecoration(
                  labelText: 'Loại phòng *',
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                items: roomTypes
                    .map((type) => DropdownMenuItem(
                          value: type.id,
                          child: Text('${type.name} - ${type.formattedBaseRate}'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRoomTypeId = value),
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn loại phòng';
                  }
                  return null;
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Không thể tải loại phòng'),
            ),

            AppSpacing.gapVerticalMd,

            // Base Rate
            TextFormField(
              controller: _baseRateController,
              decoration: const InputDecoration(
                labelText: 'Giá cơ bản/đêm *',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'VNĐ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Giá phải lớn hơn 0';
                }
                return null;
              },
            ),

            AppSpacing.gapVerticalLg,

            // Stay Requirements Section
            _buildSectionHeader('Yêu cầu lưu trú'),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStayController,
                    decoration: const InputDecoration(
                      labelText: 'Số đêm tối thiểu',
                      prefixIcon: Icon(Icons.nights_stay),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxStayController,
                    decoration: const InputDecoration(
                      labelText: 'Số đêm tối đa',
                      hintText: 'Không giới hạn',
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
              decoration: const InputDecoration(
                labelText: 'Số ngày đặt trước (tùy chọn)',
                hintText: 'VD: 7 (đặt trước 7 ngày)',
                prefixIcon: Icon(Icons.schedule),
              ),
              keyboardType: TextInputType.number,
            ),

            AppSpacing.gapVerticalLg,

            // Cancellation Policy Section
            _buildSectionHeader('Chính sách hủy'),

            DropdownButtonFormField<CancellationPolicy>(
              value: _cancellationPolicy,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.policy),
              ),
              items: CancellationPolicy.values
                  .map((policy) => DropdownMenuItem(
                        value: policy,
                        child: Text(policy.displayName),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _cancellationPolicy = value);
                }
              },
            ),

            AppSpacing.gapVerticalLg,

            // Valid Date Range Section
            _buildSectionHeader('Thời gian hiệu lực'),

            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Từ ngày',
                    value: _validFrom,
                    onChanged: (date) => setState(() => _validFrom = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DatePickerField(
                    label: 'Đến ngày',
                    value: _validTo,
                    onChanged: (date) => setState(() => _validTo = date),
                    firstDate: _validFrom,
                  ),
                ),
              ],
            ),

            AppSpacing.gapVerticalLg,

            // Options Section
            _buildSectionHeader('Tùy chọn'),

            SwitchListTile(
              title: const Text('Bao gồm bữa sáng'),
              subtitle: const Text('Gói giá này bao gồm bữa sáng miễn phí'),
              value: _includesBreakfast,
              onChanged: (value) => setState(() => _includesBreakfast = value),
              secondary: const Icon(Icons.free_breakfast),
            ),

            SwitchListTile(
              title: const Text('Đang hoạt động'),
              subtitle: const Text('Hiển thị và áp dụng gói giá này'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: const Icon(Icons.toggle_on),
            ),

            AppSpacing.gapVerticalMd,

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Ghi chú thêm về gói giá...',
                prefixIcon: Icon(Icons.description),
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
              label: Text(_isEditing ? 'Cập nhật' : 'Tạo gói giá'),
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

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(ratePlanNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.updateRatePlan(widget.ratePlanId!, {
          'name': _nameController.text.trim(),
          'name_en': _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
          'room_type': _selectedRoomTypeId,
          'base_rate': int.parse(_baseRateController.text),
          'is_active': _isActive,
          'min_stay': int.tryParse(_minStayController.text) ?? 1,
          'max_stay': _maxStayController.text.isEmpty ? null : int.parse(_maxStayController.text),
          'advance_booking_days': _advanceBookingController.text.isEmpty ? null : int.parse(_advanceBookingController.text),
          'cancellation_policy': _cancellationPolicy.name,
          'valid_from': _validFrom?.toIso8601String().split('T')[0],
          'valid_to': _validTo?.toIso8601String().split('T')[0],
          'includes_breakfast': _includesBreakfast,
          'description': _descriptionController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật gói giá "${_nameController.text}"'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final request = RatePlanCreateRequest(
          name: _nameController.text.trim(),
          nameEn: _nameEnController.text.trim().isEmpty ? null : _nameEnController.text.trim(),
          roomType: _selectedRoomTypeId!,
          baseRate: double.parse(_baseRateController.text),
          isActive: _isActive,
          minStay: int.tryParse(_minStayController.text) ?? 1,
          maxStay: _maxStayController.text.isEmpty ? null : int.parse(_maxStayController.text),
          advanceBookingDays: _advanceBookingController.text.isEmpty ? null : int.parse(_advanceBookingController.text),
          cancellationPolicy: _cancellationPolicy,
          validFrom: _validFrom,
          validTo: _validTo,
          includesBreakfast: _includesBreakfast,
          description: _descriptionController.text.trim(),
        );

        await notifier.createRatePlan(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo gói giá "${_nameController.text}"'),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa gói giá?'),
        content: Text('Bạn có chắc muốn xóa gói giá "${_nameController.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRatePlan();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRatePlan() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(ratePlanNotifierProvider.notifier);
      await notifier.deleteRatePlan(widget.ratePlanId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa gói giá "${_nameController.text}"'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
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
          value != null ? dateFormat.format(value!) : 'Chọn ngày',
          style: TextStyle(
            color: value != null ? null : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
