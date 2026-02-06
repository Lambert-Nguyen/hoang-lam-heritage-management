import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/rate_plan.dart';
import '../../models/room.dart';
import '../../providers/rate_plan_provider.dart';
import '../../providers/room_provider.dart';

/// Date Rate Override Form Screen for creating and editing date-specific pricing
class DateRateOverrideFormScreen extends ConsumerStatefulWidget {
  final int? overrideId; // null for new override

  const DateRateOverrideFormScreen({super.key, this.overrideId});

  @override
  ConsumerState<DateRateOverrideFormScreen> createState() =>
      _DateRateOverrideFormScreenState();
}

class _DateRateOverrideFormScreenState
    extends ConsumerState<DateRateOverrideFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _rateController;
  late TextEditingController _reasonController;
  late TextEditingController _minStayController;

  int? _selectedRoomTypeId;
  DateTime? _selectedDate;
  DateTime? _endDate; // For bulk creation
  bool _isBulkMode = false;
  bool _closedToArrival = false;
  bool _closedToDeparture = false;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool get _isEditing => widget.overrideId != null;

  // Common reasons for quick selection
  final List<String> _commonReasons = [
    'Cuối tuần',
    'Ngày lễ',
    'Tết Nguyên Đán',
    'Giáng sinh',
    'Mùa hè',
    'Mùa thấp điểm',
    'Khuyến mãi',
    'Sự kiện đặc biệt',
  ];

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController();
    _reasonController = TextEditingController();
    _minStayController = TextEditingController();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _reasonController.dispose();
    _minStayController.dispose();
    super.dispose();
  }

  void _initFromOverride(DateRateOverride override) {
    if (_isInitialized) return;
    _isInitialized = true;

    _rateController.text = override.rate.toInt().toString();
    _reasonController.text = override.reason;
    _minStayController.text = override.minStay?.toString() ?? '';

    _selectedRoomTypeId = override.roomType;
    _selectedDate = override.date;
    _closedToArrival = override.closedToArrival;
    _closedToDeparture = override.closedToDeparture;
  }

  @override
  Widget build(BuildContext context) {
    final roomTypesAsync = ref.watch(roomTypesProvider);

    // Load existing override for editing
    if (_isEditing) {
      final overrideAsync = ref.watch(dateRateOverrideByIdProvider(widget.overrideId!));
      return overrideAsync.when(
        data: (override) {
          _initFromOverride(override);
          return _buildForm(roomTypesAsync);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Sửa giá theo ngày')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Sửa giá theo ngày')),
          body: Center(child: Text('Lỗi: $error')),
        ),
      );
    }

    return _buildForm(roomTypesAsync);
  }

  Widget _buildForm(AsyncValue<List<RoomType>> roomTypesAsync) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa giá theo ngày' : 'Thêm giá theo ngày'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Xóa',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Bulk mode toggle (only for new)
            if (!_isEditing) ...[
              SwitchListTile(
                title: const Text('Tạo cho nhiều ngày'),
                subtitle: const Text('Áp dụng cho một khoảng thời gian'),
                value: _isBulkMode,
                onChanged: (value) => setState(() => _isBulkMode = value),
                secondary: const Icon(Icons.date_range),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Room Type
            _buildSectionHeader('Loại phòng'),
            roomTypesAsync.when(
              data: (roomTypes) => DropdownButtonFormField<int>(
                value: _selectedRoomTypeId,
                decoration: const InputDecoration(
                  labelText: 'Chọn loại phòng *',
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

            AppSpacing.gapVerticalLg,

            // Date Selection
            _buildSectionHeader(_isBulkMode ? 'Khoảng thời gian' : 'Ngày áp dụng'),

            if (_isBulkMode) ...[
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Từ ngày *',
                      value: _selectedDate,
                      onChanged: (date) => setState(() => _selectedDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Đến ngày *',
                      value: _endDate,
                      onChanged: (date) => setState(() => _endDate = date),
                      firstDate: _selectedDate,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _DatePickerField(
                label: 'Chọn ngày *',
                value: _selectedDate,
                onChanged: (date) => setState(() => _selectedDate = date),
              ),
            ],

            AppSpacing.gapVerticalLg,

            // Rate
            _buildSectionHeader('Giá'),
            TextFormField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Giá cho ngày này *',
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

            // Reason
            _buildSectionHeader('Lý do'),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do điều chỉnh giá',
                hintText: 'VD: Tết, Lễ hội, Cuối tuần...',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),

            AppSpacing.gapVerticalSm,

            // Quick reason chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonReasons
                  .map((reason) => ActionChip(
                        label: Text(reason),
                        onPressed: () =>
                            setState(() => _reasonController.text = reason),
                        backgroundColor: _reasonController.text == reason
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : null,
                      ))
                  .toList(),
            ),

            AppSpacing.gapVerticalLg,

            // Restrictions Section
            _buildSectionHeader('Hạn chế (tùy chọn)'),

            SwitchListTile(
              title: const Text('Đóng nhận khách'),
              subtitle: const Text('Không cho phép check-in ngày này'),
              value: _closedToArrival,
              onChanged: (value) => setState(() => _closedToArrival = value),
              secondary: Icon(
                Icons.no_meeting_room,
                color: _closedToArrival ? AppColors.warning : null,
              ),
            ),

            SwitchListTile(
              title: const Text('Đóng trả phòng'),
              subtitle: const Text('Không cho phép check-out ngày này'),
              value: _closedToDeparture,
              onChanged: (value) => setState(() => _closedToDeparture = value),
              secondary: Icon(
                Icons.exit_to_app,
                color: _closedToDeparture ? AppColors.warning : null,
              ),
            ),

            AppSpacing.gapVerticalMd,

            // Min Stay
            TextFormField(
              controller: _minStayController,
              decoration: const InputDecoration(
                labelText: 'Số đêm tối thiểu (tùy chọn)',
                hintText: 'Yêu cầu ở tối thiểu X đêm',
                prefixIcon: Icon(Icons.nights_stay),
              ),
              keyboardType: TextInputType.number,
            ),

            AppSpacing.gapVerticalXl,

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveOverride,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing
                  ? 'Cập nhật'
                  : _isBulkMode
                      ? 'Tạo giá cho nhiều ngày'
                      : 'Tạo giá theo ngày'),
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

  Future<void> _saveOverride() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomTypeId == null) {
      _showError('Vui lòng chọn loại phòng');
      return;
    }
    if (_selectedDate == null) {
      _showError('Vui lòng chọn ngày');
      return;
    }
    if (_isBulkMode && _endDate == null) {
      _showError('Vui lòng chọn ngày kết thúc');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(dateRateOverrideNotifierProvider.notifier);

      if (_isEditing) {
        await notifier.updateOverride(widget.overrideId!, {
          'room_type': _selectedRoomTypeId,
          'date': _selectedDate!.toIso8601String().split('T')[0],
          'rate': int.parse(_rateController.text),
          'reason': _reasonController.text.trim(),
          'closed_to_arrival': _closedToArrival,
          'closed_to_departure': _closedToDeparture,
          'min_stay': _minStayController.text.isEmpty
              ? null
              : int.parse(_minStayController.text),
        });

        if (mounted) {
          _showSuccess('Đã cập nhật giá theo ngày');
          Navigator.of(context).pop(true);
        }
      } else if (_isBulkMode) {
        // Bulk create
        final request = DateRateOverrideBulkCreateRequest(
          roomType: _selectedRoomTypeId!,
          startDate: _selectedDate!,
          endDate: _endDate!,
          rate: double.parse(_rateController.text),
          reason: _reasonController.text.trim(),
          closedToArrival: _closedToArrival,
          closedToDeparture: _closedToDeparture,
          minStay: _minStayController.text.isEmpty
              ? null
              : int.parse(_minStayController.text),
        );

        await notifier.bulkCreateOverrides(request);

        if (mounted) {
          final days = _endDate!.difference(_selectedDate!).inDays + 1;
          _showSuccess('Đã tạo giá cho $days ngày');
          Navigator.of(context).pop(true);
        }
      } else {
        // Single create
        final request = DateRateOverrideCreateRequest(
          roomType: _selectedRoomTypeId!,
          date: _selectedDate!,
          rate: double.parse(_rateController.text),
          reason: _reasonController.text.trim(),
          closedToArrival: _closedToArrival,
          closedToDeparture: _closedToDeparture,
          minStay: _minStayController.text.isEmpty
              ? null
              : int.parse(_minStayController.text),
        );

        await notifier.createOverride(request);

        if (mounted) {
          _showSuccess('Đã tạo giá theo ngày');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      _showError('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giá theo ngày?'),
        content: Text(
            'Bạn có chắc muốn xóa giá cho ngày ${_selectedDate != null ? dateFormat.format(_selectedDate!) : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteOverride();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOverride() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(dateRateOverrideNotifierProvider.notifier);
      await notifier.deleteOverride(widget.overrideId!);

      if (mounted) {
        _showSuccess('Đã xóa giá theo ngày');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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
          firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          onChanged(date);
        }
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
