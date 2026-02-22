"""
Data retention policy for Hoang Lam Heritage Management.

Defines retention periods and cleanup logic for each model category.
Used by both the Celery task and the management command.

Retention periods:
- Notifications: 90 days
- Device tokens (inactive): 30 days
- Guest messages: 2 years
- Housekeeping tasks (completed): 1 year
- Maintenance requests (completed): 2 years
- Room inspections (completed): 1 year
- Lost & found (disposed): 2 years
- Bookings (checked_out/cancelled/no_show): 3 years
- Night audits (closed): 5 years
- Financial entries (unlinked): 5 years
- Exchange rates: 3 years
- Date rate overrides: 3 years
- Sensitive data access logs: 7 years
"""

import logging
from datetime import timedelta

from django.conf import settings
from django.utils import timezone

logger = logging.getLogger("hotel_api")

# Default retention periods in days
DATA_RETENTION_DAYS = {
    "notification": 90,
    "device_token": 30,
    "guest_message": 730,
    "housekeeping_task": 365,
    "maintenance_request": 730,
    "room_inspection": 365,
    "lost_and_found": 730,
    "booking": 1095,
    "night_audit": 1825,
    "financial_entry": 1825,
    "exchange_rate": 1095,
    "date_rate_override": 1095,
    "sensitive_data_access_log": 2555,
}


def _get_retention_days():
    """Get retention days with optional overrides from settings."""
    days = DATA_RETENTION_DAYS.copy()
    overrides = getattr(settings, "DATA_RETENTION_OVERRIDES", "")
    if overrides:
        for pair in overrides.split(","):
            pair = pair.strip()
            if "=" in pair:
                model, value = pair.split("=", 1)
                try:
                    days[model.strip()] = int(value.strip())
                except ValueError:
                    pass
    return days


def _cutoff(days):
    """Return the cutoff datetime for the given number of days."""
    return timezone.now() - timedelta(days=days)


def apply_retention_policy(dry_run=False, model_filter=None):
    """
    Apply data retention policy — delete records past their retention period.

    Args:
        dry_run: If True, only count records without deleting.
        model_filter: If set, only process the specified model name.

    Returns:
        dict of {model_name: deleted_count}
    """
    from hotel_api.models import (
        Booking,
        DateRateOverride,
        DeviceToken,
        ExchangeRate,
        FinancialEntry,
        GuestMessage,
        HousekeepingTask,
        LostAndFound,
        MaintenanceRequest,
        NightAudit,
        Notification,
        RoomInspection,
        SensitiveDataAccessLog,
    )

    days = _get_retention_days()
    results = {}

    cleanup_specs = [
        (
            "notification",
            Notification.objects.filter(created_at__lt=_cutoff(days["notification"])),
        ),
        (
            "device_token",
            DeviceToken.objects.filter(
                is_active=False, updated_at__lt=_cutoff(days["device_token"])
            ),
        ),
        (
            "guest_message",
            GuestMessage.objects.filter(created_at__lt=_cutoff(days["guest_message"])),
        ),
        (
            "housekeeping_task",
            HousekeepingTask.objects.filter(
                status__in=[
                    HousekeepingTask.Status.COMPLETED,
                    HousekeepingTask.Status.VERIFIED,
                ],
                created_at__lt=_cutoff(days["housekeeping_task"]),
            ),
        ),
        (
            "maintenance_request",
            MaintenanceRequest.objects.filter(
                status__in=[
                    MaintenanceRequest.Status.COMPLETED,
                    MaintenanceRequest.Status.CANCELLED,
                ],
                created_at__lt=_cutoff(days["maintenance_request"]),
            ),
        ),
        (
            "room_inspection",
            RoomInspection.objects.filter(
                completed_at__isnull=False,
                created_at__lt=_cutoff(days["room_inspection"]),
            ),
        ),
        (
            "lost_and_found",
            LostAndFound.objects.filter(
                status=LostAndFound.Status.DISPOSED,
                created_at__lt=_cutoff(days["lost_and_found"]),
            ),
        ),
        (
            "booking",
            Booking.objects.filter(
                status__in=[
                    Booking.Status.CHECKED_OUT,
                    Booking.Status.CANCELLED,
                    Booking.Status.NO_SHOW,
                ],
                check_out_date__lt=_cutoff(days["booking"]).date(),
            ),
        ),
        (
            "night_audit",
            NightAudit.objects.filter(
                status=NightAudit.Status.CLOSED,
                audit_date__lt=_cutoff(days["night_audit"]).date(),
            ),
        ),
        (
            "financial_entry",
            FinancialEntry.objects.filter(
                booking__isnull=True,
                date__lt=_cutoff(days["financial_entry"]).date(),
            ),
        ),
        (
            "exchange_rate",
            ExchangeRate.objects.filter(date__lt=_cutoff(days["exchange_rate"]).date()),
        ),
        (
            "date_rate_override",
            DateRateOverride.objects.filter(date__lt=_cutoff(days["date_rate_override"]).date()),
        ),
        (
            "sensitive_data_access_log",
            SensitiveDataAccessLog.objects.filter(
                timestamp__lt=_cutoff(days["sensitive_data_access_log"])
            ),
        ),
    ]

    for model_name, queryset in cleanup_specs:
        if model_filter and model_name != model_filter:
            continue

        count = queryset.count()
        if count > 0 and not dry_run:
            queryset.delete()

        results[model_name] = count
        action = "Would delete" if dry_run else "Deleted"
        if count > 0:
            logger.info(
                "RETENTION: %s %d %s record(s) (retention: %d days)",
                action,
                count,
                model_name,
                days[model_name],
            )

    return results
