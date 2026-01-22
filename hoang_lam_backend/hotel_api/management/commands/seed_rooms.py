"""Management command to seed 7 rooms for Hoang Lam Heritage."""

from django.core.management.base import BaseCommand

from hotel_api.models import Room, RoomType


class Command(BaseCommand):
    """Seed 7 rooms for Hoang Lam Heritage hotel."""

    help = "Create 7 rooms for Hoang Lam Heritage hotel"

    def handle(self, *args, **options):
        """Execute command."""
        self.stdout.write("Creating 7 rooms for Hoang Lam Heritage...")

        # Get room types
        try:
            single = RoomType.objects.get(name="Phòng Đơn")
            double = RoomType.objects.get(name="Phòng Đôi")
            family = RoomType.objects.get(name="Phòng Gia Đình")
            vip = RoomType.objects.get(name="Phòng VIP")
        except RoomType.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(
                    "Error: Room types not found. Please run 'seed_room_types' first."
                )
            )
            return

        # Define 7 rooms for the hotel
        rooms_data = [
            {
                "number": "101",
                "name": "Phòng Đơn Tầng 1",
                "room_type": single,
                "floor": 1,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Cửa sổ lớn", "Gần lễ tân"],
                "notes": "Phòng đơn tiêu chuẩn tầng 1, thuận tiện cho khách check-in muộn",
            },
            {
                "number": "102",
                "name": "Phòng Đôi Tầng 1",
                "room_type": double,
                "floor": 1,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Cửa sổ lớn", "View sân"],
                "notes": "Phòng đôi tầng 1 với view sân vườn nhỏ",
            },
            {
                "number": "201",
                "name": "Phòng Đôi Tầng 2",
                "room_type": double,
                "floor": 2,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Ban công nhỏ", "View đường"],
                "notes": "Phòng đôi tầng 2 với ban công",
            },
            {
                "number": "202",
                "name": "Phòng Gia Đình Tầng 2",
                "room_type": family,
                "floor": 2,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Ban công rộng", "View đẹp"],
                "notes": "Phòng gia đình rộng rãi với ban công tầng 2",
            },
            {
                "number": "203",
                "name": "Phòng Đôi Premium Tầng 2",
                "room_type": double,
                "floor": 2,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Ban công", "Yên tĩnh"],
                "notes": "Phòng đôi cuối hành lang, yên tĩnh hơn",
            },
            {
                "number": "301",
                "name": "Phòng VIP Tầng 3",
                "room_type": vip,
                "floor": 3,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Ban công lớn", "View toàn cảnh", "Bồn tắm"],
                "notes": "Phòng VIP tầng cao nhất với view đẹp nhất",
            },
            {
                "number": "302",
                "name": "Phòng Gia Đình Premium Tầng 3",
                "room_type": family,
                "floor": 3,
                "status": Room.Status.AVAILABLE,
                "amenities": ["Ban công lớn", "View đẹp", "Yên tĩnh"],
                "notes": "Phòng gia đình tầng cao với không gian thoáng mát",
            },
        ]

        created_count = 0
        updated_count = 0

        for data in rooms_data:
            room, created = Room.objects.update_or_create(
                number=data["number"], defaults=data
            )

            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f"✓ Created: Room {room.number} - {room.name} ({room.room_type.name})"
                    )
                )
            else:
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(
                        f"↻ Updated: Room {room.number} - {room.name} ({room.room_type.name})"
                    )
                )

        self.stdout.write("\n" + "=" * 60)
        self.stdout.write(
            self.style.SUCCESS(
                f"Completed! Total rooms: {Room.objects.count()}"
            )
        )
        self.stdout.write(f"Created: {created_count}, Updated: {updated_count}")
        self.stdout.write("=" * 60)

        # Display room summary by type
        self.stdout.write("\nRoom Summary by Type:")
        for room_type in RoomType.objects.all():
            count = room_type.rooms.count()
            self.stdout.write(f"  • {room_type.name}: {count} rooms")
