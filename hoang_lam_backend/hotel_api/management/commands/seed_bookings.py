"""
Management command to seed sample bookings.
Usage: python manage.py seed_bookings
"""

from datetime import date, timedelta

from django.core.management.base import BaseCommand

from hotel_api.models import Booking, Guest, Room


class Command(BaseCommand):
    """Seed sample bookings."""

    help = "Seed sample bookings for development and testing"

    def handle(self, *args, **options):
        """Execute the command."""
        # Check if we have guests and rooms
        if not Guest.objects.exists():
            self.stdout.write(
                self.style.ERROR("No guests found! Please run: python manage.py seed_guests")
            )
            return

        if not Room.objects.exists():
            self.stdout.write(
                self.style.ERROR(
                    "No rooms found! Please run: python manage.py seed_room_types && python manage.py seed_rooms"
                )
            )
            return

        # Clear existing bookings
        Booking.objects.all().delete()
        self.stdout.write(self.style.WARNING("Cleared existing bookings"))

        # Get some guests and rooms for bookings
        guests = list(Guest.objects.all()[:8])
        rooms = list(Room.objects.filter(is_active=True)[:6])

        if len(guests) < 5 or len(rooms) < 3:
            self.stdout.write(
                self.style.ERROR("Not enough guests or rooms! Need at least 5 guests and 3 rooms.")
            )
            return

        today = date.today()

        bookings_data = [
            # Past bookings (checked out)
            {
                "guest": guests[0],
                "room": rooms[0],
                "check_in_date": today - timedelta(days=10),
                "check_out_date": today - timedelta(days=7),
                "status": Booking.Status.CHECKED_OUT,
                "source": Booking.Source.WEBSITE,
                "payment_method": Booking.PaymentMethod.CARD,
                "nightly_rate": 1000000,
                "total_amount": 3000000,
                "deposit_amount": 3000000,
                "notes": "Khách VIP, đã thanh toán đầy đủ",
            },
            {
                "guest": guests[1],
                "room": rooms[1],
                "check_in_date": today - timedelta(days=15),
                "check_out_date": today - timedelta(days=12),
                "status": Booking.Status.CHECKED_OUT,
                "source": Booking.Source.PHONE,
                "payment_method": Booking.PaymentMethod.CASH,
                "nightly_rate": 800000,
                "total_amount": 2400000,
                "deposit_amount": 1200000,
                "notes": "Khách đoàn",
            },
            # Current bookings (checked in)
            {
                "guest": guests[2],
                "room": rooms[2],
                "check_in_date": today - timedelta(days=2),
                "check_out_date": today + timedelta(days=1),
                "status": Booking.Status.CHECKED_IN,
                "source": Booking.Source.BOOKING_COM,
                "payment_method": Booking.PaymentMethod.OTA_COLLECT,
                "nightly_rate": 1500000,
                "total_amount": 4500000,
                "deposit_amount": 0,
                "notes": "Booking.com - đã thanh toán qua OTA",
            },
            {
                "guest": guests[3],
                "room": rooms[3],
                "check_in_date": today - timedelta(days=1),
                "check_out_date": today + timedelta(days=2),
                "status": Booking.Status.CHECKED_IN,
                "source": Booking.Source.WALK_IN,
                "payment_method": Booking.PaymentMethod.CASH,
                "nightly_rate": 900000,
                "total_amount": 2700000,
                "deposit_amount": 1000000,
                "notes": "Khách walk-in",
            },
            # Today's check-ins
            {
                "guest": guests[4],
                "room": rooms[4],
                "check_in_date": today,
                "check_out_date": today + timedelta(days=3),
                "status": Booking.Status.CONFIRMED,
                "source": Booking.Source.AGODA,
                "payment_method": Booking.PaymentMethod.OTA_COLLECT,
                "nightly_rate": 2700000,
                "total_amount": 8100000,
                "deposit_amount": 0,
                "notes": "Agoda booking",
            },
            {
                "guest": guests[5],
                "room": rooms[5],
                "check_in_date": today,
                "check_out_date": today + timedelta(days=2),
                "status": Booking.Status.CONFIRMED,
                "source": Booking.Source.WEBSITE,
                "payment_method": Booking.PaymentMethod.BANK_TRANSFER,
                "nightly_rate": 2700000,
                "total_amount": 5400000,
                "deposit_amount": 2700000,
                "notes": "Đã chuyển khoản 50%",
            },
            # Tomorrow's check-ins
            {
                "guest": guests[6],
                "room": rooms[0],
                "check_in_date": today + timedelta(days=1),
                "check_out_date": today + timedelta(days=4),
                "status": Booking.Status.CONFIRMED,
                "source": Booking.Source.PHONE,
                "payment_method": Booking.PaymentMethod.MOMO,
                "nightly_rate": 2700000,
                "total_amount": 8100000,
                "deposit_amount": 3000000,
                "notes": "Đã thanh toán đặt cọc qua MoMo",
            },
            {
                "guest": guests[7],
                "room": rooms[1],
                "check_in_date": today + timedelta(days=1),
                "check_out_date": today + timedelta(days=3),
                "status": Booking.Status.PENDING,
                "source": Booking.Source.WEBSITE,
                "payment_method": Booking.PaymentMethod.CASH,
                "nightly_rate": 2400000,
                "total_amount": 4800000,
                "deposit_amount": 0,
                "notes": "Chưa xác nhận, chờ thanh toán",
            },
            # Future bookings
            {
                "guest": guests[0],
                "room": rooms[2],
                "check_in_date": today + timedelta(days=7),
                "check_out_date": today + timedelta(days=10),
                "status": Booking.Status.CONFIRMED,
                "source": Booking.Source.WEBSITE,
                "payment_method": Booking.PaymentMethod.VNPAY,
                "nightly_rate": 2700000,
                "total_amount": 8100000,
                "deposit_amount": 4050000,
                "notes": "Khách VIP đặt lại, đã thanh toán 50% qua VNPay",
            },
            {
                "guest": guests[1],
                "room": rooms[3],
                "check_in_date": today + timedelta(days=14),
                "check_out_date": today + timedelta(days=17),
                "status": Booking.Status.CONFIRMED,
                "source": Booking.Source.AIRBNB,
                "payment_method": Booking.PaymentMethod.OTA_COLLECT,
                "nightly_rate": 2400000,
                "total_amount": 7200000,
                "deposit_amount": 0,
                "notes": "Airbnb booking",
            },
            # Cancelled booking
            {
                "guest": guests[2],
                "room": rooms[4],
                "check_in_date": today + timedelta(days=5),
                "check_out_date": today + timedelta(days=7),
                "status": Booking.Status.CANCELLED,
                "source": Booking.Source.PHONE,
                "payment_method": Booking.PaymentMethod.CASH,
                "nightly_rate": 2400000,
                "total_amount": 4800000,
                "deposit_amount": 1000000,
                "notes": "Khách hủy, đã hoàn tiền đặt cọc",
            },
        ]

        created_count = 0
        for booking_data in bookings_data:
            try:
                booking = Booking.objects.create(**booking_data)
                created_count += 1

                status_emoji = {
                    Booking.Status.PENDING: "⏳",
                    Booking.Status.CONFIRMED: "✓",
                    Booking.Status.CHECKED_IN: "🏠",
                    Booking.Status.CHECKED_OUT: "✈️",
                    Booking.Status.CANCELLED: "❌",
                    Booking.Status.NO_SHOW: "⚠️",
                }

                self.stdout.write(
                    self.style.SUCCESS(
                        f"{status_emoji.get(booking.status, '•')} Created: "
                        f"{booking.guest.full_name} - Room {booking.room.number} - "
                        f"{booking.check_in_date} to {booking.check_out_date} - "
                        f"{booking.get_status_display()}"
                    )
                )
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(
                        f"Failed to create booking for {booking_data['guest'].full_name}: {str(e)}"
                    )
                )

        self.stdout.write(
            self.style.SUCCESS(f"\n{'=' * 50}\nSuccessfully created {created_count} bookings!")
        )
        self.stdout.write(
            self.style.SUCCESS(f"Total bookings in database: {Booking.objects.count()}")
        )

        # Show status statistics
        self.stdout.write("\nBooking statistics:")
        for status in Booking.Status:
            count = Booking.objects.filter(status=status).count()
            if count > 0:
                self.stdout.write(f"  {status.label}: {count}")

        # Show today's activity
        today_checkins = Booking.objects.filter(check_in_date=today).count()
        today_checkouts = Booking.objects.filter(check_out_date=today).count()
        currently_checked_in = Booking.objects.filter(status=Booking.Status.CHECKED_IN).count()

        self.stdout.write("\nToday's activity:")
        self.stdout.write(f"  Check-ins today: {today_checkins}")
        self.stdout.write(f"  Check-outs today: {today_checkouts}")
        self.stdout.write(f"  Currently checked in: {currently_checked_in}")
