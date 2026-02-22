import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
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
  ConsumerState<GroupBookingFormScreen> createState() =>
      _GroupBookingFormScreenState();
}

class _GroupBookingFormScreenState
    extends ConsumerState<GroupBookingFormScreen> {
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
    final l10n = AppLocalizations.of(context)!;
    if (widget.isEditing) {
      final bookingAsync = ref.watch(
        groupBookingByIdProvider(widget.bookingId!),
      );
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editGroupBooking)),
        body: bookingAsync.when(
          data: (booking) {
            _initializeFromBooking(booking);
            return _buildForm();
          },
          loading: () => const LoadingIndicator(),
          error:
              (e, _) => ErrorDisplay(
                message: '${l10n.error}: $e',
                onRetry:
                    () => ref.invalidate(
                      groupBookingByIdProvider(widget.bookingId!),
                    ),
              ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGroupBooking)),
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
            _SectionTitle(title: context.l10n.groupInfo),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: '${context.l10n.groupNameRequired} *',
                      hint: context.l10n.exampleGroupName,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? context.l10n.pleaseEnterValue
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _roomCountController,
                            label: '${context.l10n.numberOfRooms} *',
                            keyboardType: TextInputType.number,
                            validator:
                                (v) =>
                                    v == null ||
                                            v.isEmpty ||
                                            int.tryParse(v) == null ||
                                            int.parse(v) < 1
                                        ? context.l10n.invalid
                                        : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            controller: _guestCountController,
                            label: '${context.l10n.numberOfGuests} *',
                            keyboardType: TextInputType.number,
                            validator:
                                (v) =>
                                    v == null ||
                                            v.isEmpty ||
                                            int.tryParse(v) == null ||
                                            int.parse(v) < 1
                                        ? context.l10n.invalid
                                        : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: context.l10n.contactInfo),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _contactNameController,
                      label: '${context.l10n.contactPersonRequired} *',
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? context.l10n.pleaseEnterValue
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _contactPhoneController,
                      label: '${context.l10n.phoneRequired} *',
                      keyboardType: TextInputType.phone,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? context.l10n.pleaseEnterValue
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _contactEmailController,
                      label: context.l10n.emailLabel,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: context.l10n.stayPeriod),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    _buildDatePicker(
                      context.l10n.checkInDateRequired,
                      _checkInDate,
                      (d) {
                        setState(() {
                          _checkInDate = d;
                          if (_checkOutDate.isBefore(_checkInDate))
                            _checkOutDate = _checkInDate.add(
                              const Duration(days: 1),
                            );
                        });
                      },
                      DateTime.now(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDatePicker(
                      context.l10n.checkOutDateRequired,
                      _checkOutDate,
                      (d) => setState(() => _checkOutDate = d),
                      _checkInDate.add(const Duration(days: 1)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.nightsCountDisplay.replaceAll(
                            '{count}',
                            '${_checkOutDate.difference(_checkInDate).inDays}',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: context.l10n.payment),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _totalAmountController,
                      label: '${context.l10n.totalAmountVnd} *',
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null ||
                                      v.isEmpty ||
                                      double.tryParse(v) == null
                                  ? context.l10n.invalid
                                  : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _depositAmountController,
                            label: context.l10n.depositVnd,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            controller: _discountController,
                            label: context.l10n.discountPercent,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      title: Text(context.l10n.depositPaidLabel),
                      value: _depositPaid,
                      onChanged: (v) => setState(() => _depositPaid = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: context.l10n.additionalInfoSection),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _specialRequestsController,
                      label: context.l10n.specialRequests,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _notesController,
                      label: context.l10n.notes,
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
                label:
                    widget.isEditing
                        ? context.l10n.update
                        : context.l10n.createBooking,
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

  Widget _buildDatePicker(
    String label,
    DateTime date,
    ValueChanged<DateTime> onSelect,
    DateTime firstDate,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onSelect(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
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
          ref.invalidate(groupBookingsProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.groupUpdated)));
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
          ref.invalidate(groupBookingsProvider);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.bookingCreated)));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );
}
