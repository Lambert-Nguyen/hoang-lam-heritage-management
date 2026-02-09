"""
Management command to send check-in reminder notifications.

Run daily via cron:
    0 9 * * * cd /path/to/project && python manage.py send_checkin_reminders
"""

from datetime import date

from django.core.management.base import BaseCommand

from hotel_api.models import Booking, Notification
from hotel_api.services import PushNotificationService


class Command(BaseCommand):
    help = "Send check-in reminder notifications for today's expected check-ins"

    def handle(self, *args, **options):
        today = date.today()

        pending_checkins = Booking.objects.filter(
            check_in_date=today,
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
        ).select_related("guest", "room")

        if not pending_checkins.exists():
            self.stdout.write("No pending check-ins for today.")
            return

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

        self.stdout.write(self.style.SUCCESS(f"Sent {count} check-in reminder(s)."))
