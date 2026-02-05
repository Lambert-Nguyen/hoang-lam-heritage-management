import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/group_booking.dart';
import '../../providers/group_booking_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_input.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/loading_indicator.dart';

/// Form screen for creating/editing group bookings
class GroupBookingFormScreen extends ConsumerStatefulWidget {
  final int? bookingId;
  const GroupBookingFormScreen({super.key, this.bookingId});
  bool get isEditing => bookingId != null;

  @override
  ConsumerState<GroupBookingFormScreen> createState() => _GroupBookingFormScreenState();
}

class _GroupBookingFormScreenState extends ConsumerState<GroupBookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;
  late TextEditingController _roomCountController;
  late TextEditingController _guestCountController;
  late TextEditingController _totalAmountController;
  late TextEditingController _depositAmountController;
  late TextEditingController _discountController;
  late TextEditingController _specialRequestsController;
  late TextEditingController _notesController;

  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 2));
  bool _depositPaid = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _contactEmailController = TextEditingController();
    _roomCountController = TextEditingController();
    _guestCountController = TextEditingController();
    _totalAmountController = TextEditingController();
    _depositAmountController = TextEditingController();
    _discountController = TextEditingController(text: '0');
    _specialRequestsController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _roomCountController.dispose();
    _guestCountController.dispose();
    _totalAmountController.dispose();
    _depositAmountController.dispose();
    _discountController.dispose();
    _specialRequestsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFromBooking(GroupBooking booking) {
    if (_isInitialized) return;
    _isInitialized = true;
    _nameController.text = booking.name;
    _contactNameController.text = booking.contactName;
    _contactPhoneController.text = booking.contactPhone;
    _contactEmailController.text = booking.contactEmail;
    _roomCountController.text = booking.roomCount.toString();
    _guestCountController.text = booking.guestCount.toString();
    _totalAmountController.text = booking.totalAmount.toStringAsFixed(0);
    _depositAmountController.text = booking.depositAmount.toStringAsFixed(0);
    _discountController.text = booking.discountPercent.toStringAsFixed(0);
    _specialRequestsController.text = booking.specialRequests;
    _notesController.text = booking.notes;
    _depositPaid = booking.depositPaid;
    try {
      _checkInDate = DateTime.parse(booking.checkInDate);
      _checkOutDate = DateTime.parse(booking.checkOutDate);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final bookingAsync = ref.watch(groupBookingByIdProvider(widget.bookingId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Sửa đặt phòng đoàn')),
        body: bookingAsync.when(
          data: (booking) {
            _initializeFromBooking(booking);
            return _buildForm();
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(message: 'Lỗi: $e', onRetry: () => ref.invalidate(groupBookingByIdProvider(widget.bookingId!))),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo đặt phòng đoàn')),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'Thông tin đoàn'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(children: [
                  AppTextField(controller: _nameController, label: 'Tên đoàn *', hint: 'VD: Đoàn du lịch ABC', validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập' : null),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(child: AppTextField(controller: _roomCountController, label: 'Số phòng *', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 1 ? 'Không hợp lệ' : null)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: AppTextField(controller: _guestCountController, label: 'Số khách *', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 1 ? 'Không hợp lệ' : null)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Thông tin liên hệ'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(children: [
                  AppTextField(controller: _contactNameController, label: 'Người liên hệ *', validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập' : null),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(controller: _contactPhoneController, label: 'Điện thoại *', keyboardType: TextInputType.phone, validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập' : null),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(controller: _contactEmailController, label: 'Email', keyboardType: TextInputType.emailAddress),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Thời gian lưu trú'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(children: [
                  _buildDatePicker('Ngày nhận phòng *', _checkInDate, (d) {
                    setState(() {
                      _checkInDate = d;
                      if (_checkOutDate.isBefore(_checkInDate)) _checkOutDate = _checkInDate.add(const Duration(days: 1));
                    });
                  }, DateTime.now()),
                  const SizedBox(height: AppSpacing.md),
                  _buildDatePicker('Ngày trả phòng *', _checkOutDate, (d) => setState(() => _checkOutDate = d), _checkInDate.add(const Duration(days: 1))),
                  const SizedBox(height: AppSpacing.sm),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Số đêm: ${_checkOutDate.difference(_checkInDate).inDays}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))]),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Thanh toán'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(children: [
                  AppTextField(controller: _totalAmountController, label: 'Tổng tiền (VNĐ) *', keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Không hợp lệ' : null),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(child: AppTextField(controller: _depositAmountController, label: 'Đặt cọc (VNĐ)', keyboardType: TextInputType.number)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: AppTextField(controller: _discountController, label: 'Giảm giá (%)', keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(title: const Text('Đã thanh toán đặt cọc'), value: _depositPaid, onChanged: (v) => setState(() => _depositPaid = v), contentPadding: EdgeInsets.zero),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Thông tin bổ sung'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(children: [
                  AppTextField(controller: _specialRequestsController, label: 'Yêu cầu đặc biệt', maxLines: 3),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(controller: _notesController, label: 'Ghi chú', maxLines: 3),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: widget.isEditing ? 'Cập nhật' : 'Tạo đặt phòng', onPressed: _isLoading ? null : _handleSubmit, isLoading: _isLoading, icon: widget.isEditing ? Icons.save : Icons.add),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, ValueChanged<DateTime> onSelect, DateTime firstDate) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date, firstDate: firstDate, lastDate: DateTime.now().add(const Duration(days: 365)));
        if (picked != null) onSelect(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
        child: Text('${date.day}/${date.month}/${date.year}'),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(groupBookingNotifierProvider.notifier);
      final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
      final depositAmount = double.tryParse(_depositAmountController.text) ?? 0;
      final discountPercent = double.tryParse(_discountController.text) ?? 0;
      final roomCount = int.tryParse(_roomCountController.text) ?? 0;
      final guestCount = int.tryParse(_guestCountController.text) ?? 0;

      if (widget.isEditing) {
        final update = GroupBookingUpdate(
          name: _nameController.text,
          contactName: _contactNameController.text,
          contactPhone: _contactPhoneController.text,
          contactEmail: _contactEmailController.text,
          checkInDate: _checkInDate.toIso8601String().split('T')[0],
          checkOutDate: _checkOutDate.toIso8601String().split('T')[0],
          roomCount: roomCount,
          guestCount: guestCount,
          totalAmount: totalAmount,
          depositAmount: depositAmount,
          depositPaid: _depositPaid,
          discountPercent: discountPercent,
          specialRequests: _specialRequestsController.text,
          notes: _notesController.text,
        );
        final result = await notifier.updateBooking(widget.bookingId!, update);
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật')));
          context.pop();
        }
      } else {
        final create = GroupBookingCreate(
          name: _nameController.text,
          contactName: _contactNameController.text,
          contactPhone: _contactPhoneController.text,
          contactEmail: _contactEmailController.text,
          checkInDate: _checkInDate.toIso8601String().split('T')[0],
          checkOutDate: _checkOutDate.toIso8601String().split('T')[0],
          roomCount: roomCount,
          guestCount: guestCount,
          totalAmount: totalAmount,
          depositAmount: depositAmount,
          depositPaid: _depositPaid,
          discountPercent: discountPercent,
          specialRequests: _specialRequestsController.text,
          notes: _notesController.text,
        );
        final result = await notifier.createBooking(create);
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo đặt phòng')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
}
