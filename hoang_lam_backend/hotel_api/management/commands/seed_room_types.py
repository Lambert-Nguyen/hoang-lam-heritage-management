"""Management command to seed default room types."""

from decimal import Decimal

from django.core.management.base import BaseCommand

from hotel_api.models import RoomType


class Command(BaseCommand):
    """Seed default room types for Hoang Lam Heritage."""

    help = "Create default room types for the hotel"

    def handle(self, *args, **options):
        """Execute command."""
        self.stdout.write("Creating default room types...")

        room_types_data = [
            {
                "name": "Phòng Đơn",
                "name_en": "Single Room",
                "base_rate": Decimal("300000"),
                "max_guests": 1,
                "description": "Phòng đơn tiêu chuẩn với 1 giường đơn, phù hợp cho 1 người",
                "amenities": [
                    "WiFi miễn phí",
                    "Điều hòa",
                    "TV màn hình phẳng",
                    "Nước nóng",
                    "Bàn làm việc",
                ],
            },
            {
                "name": "Phòng Đôi",
                "name_en": "Double Room",
                "base_rate": Decimal("400000"),
                "max_guests": 2,
                "description": "Phòng đôi tiêu chuẩn với 1 giường đôi lớn",
                "amenities": [
                    "WiFi miễn phí",
                    "Điều hòa",
                    "TV màn hình phẳng",
                    "Nước nóng",
                    "Tủ lạnh mini",
                    "Bàn làm việc",
                ],
            },
            {
                "name": "Phòng Twin",
                "name_en": "Twin Room",
                "base_rate": Decimal("400000"),
                "max_guests": 2,
                "description": "Phòng twin tiêu chuẩn với 2 giường đơn riêng biệt",
                "amenities": [
                    "WiFi miễn phí",
                    "Điều hòa",
                    "TV màn hình phẳng",
                    "Nước nóng",
                    "Tủ lạnh mini",
                    "Bàn làm việc",
                ],
            },
            {
                "name": "Phòng Gia Đình",
                "name_en": "Family Room",
                "base_rate": Decimal("600000"),
                "max_guests": 4,
                "description": "Phòng gia đình rộng rãi với 1 giường đôi và 2 giường đơn",
                "amenities": [
                    "WiFi miễn phí",
                    "Điều hòa",
                    "TV màn hình phẳng",
                    "Nước nóng",
                    "Tủ lạnh",
                    "Bàn làm việc",
                    "Sofa",
                    "Ban công",
                ],
            },
            {
                "name": "Phòng VIP",
                "name_en": "VIP Room",
                "base_rate": Decimal("800000"),
                "max_guests": 2,
                "description": "Phòng VIP cao cấp với view đẹp và tiện nghi đầy đủ",
                "amenities": [
                    "WiFi miễn phí",
                    "Điều hòa",
                    "TV Smart 43 inch",
                    "Nước nóng",
                    "Tủ lạnh",
                    "Minibar",
                    "Bàn làm việc",
                    "Sofa",
                    "Ban công riêng",
                    "Bồn tắm",
                ],
            },
        ]

        created_count = 0
        updated_count = 0

        for data in room_types_data:
            room_type, created = RoomType.objects.update_or_create(name=data["name"], defaults=data)

            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f"✓ Created: {room_type.name} ({room_type.name_en})")
                )
            else:
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f"↻ Updated: {room_type.name} ({room_type.name_en})")
                )

        self.stdout.write("\n" + "=" * 60)
        self.stdout.write(
            self.style.SUCCESS(f"Completed! Created: {created_count}, Updated: {updated_count}")
        )
        self.stdout.write("=" * 60)
