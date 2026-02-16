"""
Celery tasks for Hoang Lam Heritage Management.

Migrated from management commands to enable scheduled execution via Celery Beat.
"""

import logging
from datetime import date

from celery import shared_task

logger = logging.getLogger("hotel_api")


@shared_task(name="hotel_api.tasks.send_checkin_reminders")
def send_checkin_reminders():
    """
    Send push notifications for today's expected check-ins.

    Scheduled daily at 9:00 AM via Celery Beat.
    Previously: python manage.py send_checkin_reminders
    """
    from hotel_api.models import Booking, Notification
    from hotel_api.services import PushNotificationService

    today = date.today()
    pending_checkins = Booking.objects.filter(
        check_in_date=today,
        status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
    ).select_related("guest", "room")

    if not pending_checkins.exists():
        logger.info("No pending check-ins for today.")
        return "No pending check-ins."

    count = 0
    for booking in pending_checkins:
        PushNotificationService.notify_staff(
            notification_type=Notification.NotificationType.CHECKIN_REMINDER,
            title=f"Nhắc nhận phòng: Phòng {booking.room.number}",
            body=f"{booking.guest.full_name} - Phòng {booking.room.number} cần nhận hôm nay",
            data={
                "booking_id": str(booking.id),
                "room_number": booking.room.number,
                "action": "checkin_reminder",
            },
            booking=booking,
        )
        count += 1

    logger.info(f"Sent {count} check-in reminder(s).")
    return f"Sent {count} check-in reminder(s)."


@shared_task(name="hotel_api.tasks.send_checkout_reminders")
def send_checkout_reminders():
    """
    Send push notifications for today's expected check-outs.

    Scheduled daily at 8:00 AM via Celery Beat.
    Previously: python manage.py send_checkout_reminders
    """
    from hotel_api.models import Booking, Notification
    from hotel_api.services import PushNotificationService

    today = date.today()
    pending_checkouts = Booking.objects.filter(
        check_out_date=today,
        status=Booking.Status.CHECKED_IN,
    ).select_related("guest", "room")

    if not pending_checkouts.exists():
        logger.info("No pending check-outs for today.")
        return "No pending check-outs."

    count = 0
    for booking in pending_checkouts:
        PushNotificationService.notify_staff(
            notification_type=Notification.NotificationType.CHECKOUT_REMINDER,
            title=f"Nhắc trả phòng: Phòng {booking.room.number}",
            body=f"{booking.guest.full_name} - Phòng {booking.room.number} cần trả hôm nay",
            data={
                "booking_id": str(booking.id),
                "room_number": booking.room.number,
                "action": "checkout_reminder",
            },
            booking=booking,
        )
        count += 1

    logger.info(f"Sent {count} check-out reminder(s).")
    return f"Sent {count} check-out reminder(s)."


@shared_task(name="hotel_api.tasks.cleanup_expired_tokens")
def cleanup_expired_tokens():
    """
    Remove expired and blacklisted JWT tokens from the database.

    Scheduled daily at 2:00 AM via Celery Beat.
    """
    from rest_framework_simplejwt.token_blacklist.models import OutstandingToken
    from django.utils import timezone

    expired_count = OutstandingToken.objects.filter(
        expires_at__lt=timezone.now()
    ).count()

    if expired_count > 0:
        OutstandingToken.objects.filter(expires_at__lt=timezone.now()).delete()
        logger.info(f"Cleaned up {expired_count} expired token(s).")
    else:
        logger.info("No expired tokens to clean up.")

    return f"Cleaned up {expired_count} expired token(s)."
