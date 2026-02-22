"""
Management command to seed sample guests.
Usage: python manage.py seed_guests
"""

from django.core.management.base import BaseCommand

from hotel_api.models import Guest


class Command(BaseCommand):
    """Seed sample guests."""

    help = "Seed sample guests for development and testing"

    def handle(self, *args, **options):
        """Execute the command."""
        # Clear existing guests
        Guest.objects.all().delete()
        self.stdout.write(self.style.WARNING("Cleared existing guests"))

        guests_data = [
            {
                "full_name": "Nguyễn Văn An",
                "phone": "0901234567",
                "email": "nva@example.com",
                "id_type": Guest.IDType.CCCD,
                "id_number": "001234567890",
                "nationality": "Vietnam",
                "date_of_birth": "1985-05-15",
                "gender": "male",
                "address": "123 Lê Lợi",
                "city": "TP. Hồ Chí Minh",
                "country": "Vietnam",
                "is_vip": True,
                "total_stays": 5,
                "preferences": "Tầng cao, view biển",
            },
            {
                "full_name": "Trần Thị Bình",
                "phone": "0912345678",
                "email": "ttb@example.com",
                "id_type": Guest.IDType.CCCD,
                "id_number": "001234567891",
                "nationality": "Vietnam",
                "date_of_birth": "1990-08-20",
                "gender": "female",
                "address": "456 Trần Hưng Đạo",
                "city": "Hà Nội",
                "country": "Vietnam",
                "is_vip": False,
                "total_stays": 2,
            },
            {
                "full_name": "John Smith",
                "phone": "+1234567890",
                "email": "john.smith@example.com",
                "id_type": Guest.IDType.PASSPORT,
                "id_number": "US123456789",
                "nationality": "United States",
                "date_of_birth": "1980-03-10",
                "gender": "male",
                "address": "789 Broadway",
                "city": "New York",
                "country": "United States",
                "is_vip": True,
                "total_stays": 8,
                "preferences": "Non-smoking, king bed",
            },
            {
                "full_name": "佐藤 花子",
                "phone": "+81901234567",
                "email": "hanako.sato@example.com",
                "id_type": Guest.IDType.PASSPORT,
                "id_number": "JP987654321",
                "nationality": "Japan",
                "date_of_birth": "1988-11-25",
                "gender": "female",
                "address": "1-2-3 Shibuya",
                "city": "Tokyo",
                "country": "Japan",
                "is_vip": False,
                "total_stays": 1,
            },
            {
                "full_name": "Lê Hoàng Minh",
                "phone": "0923456789",
                "email": "lhm@example.com",
                "id_type": Guest.IDType.CCCD,
                "id_number": "001234567892",
                "nationality": "Vietnam",
                "date_of_birth": "1995-01-30",
                "gender": "male",
                "address": "789 Nguyễn Huệ",
                "city": "Đà Nẵng",
                "country": "Vietnam",
                "is_vip": False,
                "total_stays": 0,
            },
            {
                "full_name": "Kim Min-ji",
                "phone": "+82101234567",
                "email": "minji.kim@example.com",
                "id_type": Guest.IDType.PASSPORT,
                "id_number": "KR246813579",
                "nationality": "South Korea",
                "date_of_birth": "1992-07-18",
                "gender": "female",
                "address": "Gangnam-gu",
                "city": "Seoul",
                "country": "South Korea",
                "is_vip": True,
                "total_stays": 4,
                "preferences": "Late check-out, quiet room",
            },
            {
                "full_name": "Wang Wei",
                "phone": "+86138001234567",
                "email": "wang.wei@example.com",
                "id_type": Guest.IDType.PASSPORT,
                "id_number": "CN135792468",
                "nationality": "China",
                "date_of_birth": "1987-09-05",
                "gender": "male",
                "address": "Chaoyang District",
                "city": "Beijing",
                "country": "China",
                "is_vip": False,
                "total_stays": 3,
            },
            {
                "full_name": "Phạm Thị Diễm",
                "phone": "0934567890",
                "email": "ptd@example.com",
                "id_type": Guest.IDType.CCCD,
                "id_number": "001234567893",
                "nationality": "Vietnam",
                "date_of_birth": "1993-12-12",
                "gender": "female",
                "address": "321 Hai Bà Trưng",
                "city": "TP. Hồ Chí Minh",
                "country": "Vietnam",
                "is_vip": False,
                "total_stays": 1,
            },
            {
                "full_name": "Michael Brown",
                "phone": "+44201234567",
                "email": "m.brown@example.com",
                "id_type": Guest.IDType.PASSPORT,
                "id_number": "GB987654321",
                "nationality": "United Kingdom",
                "date_of_birth": "1975-04-22",
                "gender": "male",
                "address": "10 Downing Street",
                "city": "London",
                "country": "United Kingdom",
                "is_vip": True,
                "total_stays": 6,
                "preferences": "Business facilities, early breakfast",
            },
            {
                "full_name": "Võ Thị Lan",
                "phone": "0945678901",
                "email": "vtl@example.com",
                "id_type": Guest.IDType.CCCD,
                "id_number": "001234567894",
                "nationality": "Vietnam",
                "date_of_birth": "1998-06-08",
                "gender": "female",
                "address": "654 Lý Thường Kiệt",
                "city": "Cần Thơ",
                "country": "Vietnam",
                "is_vip": False,
                "total_stays": 0,
            },
        ]

        created_count = 0
        for guest_data in guests_data:
            guest, created = Guest.objects.get_or_create(
                phone=guest_data["phone"],
                defaults=guest_data,
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f"✓ Created guest: {guest.full_name} ({guest.nationality})")
                )
            else:
                self.stdout.write(self.style.WARNING(f"- Guest already exists: {guest.full_name}"))

        self.stdout.write(
            self.style.SUCCESS(f"\n{'=' * 50}\nSuccessfully created {created_count} guests!")
        )
        self.stdout.write(self.style.SUCCESS(f"Total guests in database: {Guest.objects.count()}"))

        # Show VIP statistics
        vip_count = Guest.objects.filter(is_vip=True).count()
        self.stdout.write(self.style.SUCCESS(f"VIP guests: {vip_count}"))
        returning_count = Guest.objects.filter(total_stays__gt=0).count()
        self.stdout.write(self.style.SUCCESS(f"Returning guests: {returning_count}"))
