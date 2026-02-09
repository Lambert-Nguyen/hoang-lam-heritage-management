"""
Management command to send check-out reminder notifications.

Run daily via cron:
    0 8 * * * cd /path/to/project && python manage.py send_checkout_reminders
"""

from datetime import date

from django.core.management.base import BaseCommand

from hotel_api.models import Booking, Notification
from hotel_api.services import PushNotificationService


class Command(BaseCommand):
    help = "Send check-out reminder notifications for today's expected check-outs"

    def handle(self, *args, **options):
        today = date.today()

        pending_checkouts = Booking.objects.filter(
            check_out_date=today,
            status=Booking.Status.CHECKED_IN,
        ).select_related("guest", "room")

        if not pending_checkouts.exists():
            self.stdout.write("No pending check-outs for today.")
            return

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

        self.stdout.write(self.style.SUCCESS(f"Sent {count} check-out reminder(s)."))
