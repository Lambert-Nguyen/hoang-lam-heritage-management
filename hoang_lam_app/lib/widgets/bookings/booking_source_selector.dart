import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';

/// Booking Source Selector Widget - Dropdown for selecting booking source
///
/// Displays all available booking sources with icons and colors:
/// - Walk-in: Direct hotel counter bookings
/// - Phone: Telephone reservations
/// - Website: Hotel website bookings
/// - Booking.com, Agoda, Airbnb, Traveloka: OTA platforms
/// - Other OTA: Other online travel agencies
/// - Other: Miscellaneous sources
class BookingSourceSelector extends StatelessWidget {
  final BookingSource? value;
  final ValueChanged<BookingSource?> onChanged;
  final bool enabled;
  final String? hintText;
  final bool showLabel;

  const BookingSourceSelector({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BookingSource>(
      value: value,
      decoration: InputDecoration(
        labelText: showLabel ? context.l10n.bookingSource : null,
        hintText: hintText ?? context.l10n.selectBookingSourceHint,
        prefixIcon: value != null
            ? Icon(
                value!.icon,
                color: value!.color,
              )
            : const Icon(Icons.source),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: BookingSource.values.map((source) {
        return DropdownMenuItem<BookingSource>(
          value: source,
          child: Row(
            children: [
              Icon(
                source.icon,
                size: 20,
                color: source.color,
              ),
              const SizedBox(width: 12),
              Text(source.localizedName(context.l10n)),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
    );
  }
}

/// Compact version for horizontal layouts or chips
class BookingSourceChip extends StatelessWidget {
  final BookingSource source;
  final VoidCallback? onTap;
  final bool selected;

  const BookingSourceChip({
    super.key,
    required this.source,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            source.icon,
            size: 16,
            color: selected ? Colors.white : source.color,
          ),
          const SizedBox(width: 6),
          Text(source.localizedName(context.l10n)),
        ],
      ),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: source.color.withValues(alpha: 0.1),
      selectedColor: source.color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
      ),
    );
  }
}

/// Grid selector for booking form with all sources visible
class BookingSourceGrid extends StatelessWidget {
  final BookingSource? value;
  final ValueChanged<BookingSource> onChanged;
  final bool enabled;

  const BookingSourceGrid({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.bookingSource,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: BookingSource.values.length,
          itemBuilder: (context, index) {
            final source = BookingSource.values[index];
            final isSelected = value == source;

            return InkWell(
              onTap: enabled ? () => onChanged(source) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? source.color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? source.color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      source.icon,
                      size: 18,
                      color: isSelected ? source.color : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        source.localizedName(context.l10n),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? source.color : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
