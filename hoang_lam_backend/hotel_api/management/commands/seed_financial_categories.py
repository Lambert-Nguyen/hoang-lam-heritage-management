"""Management command to seed default financial categories."""

from django.core.management.base import BaseCommand

from hotel_api.models import FinancialCategory


class Command(BaseCommand):
    """Seed default income and expense categories for Hoang Lam Heritage."""

    help = "Create default financial categories for income and expenses"

    def handle(self, *args, **options):
        """Execute command."""
        self.stdout.write("Creating default financial categories...")

        # Income categories (matching Design Plan)
        income_categories = [
            {
                "name": "Tiền phòng",
                "name_en": "Room Revenue",
                "icon": "hotel",
                "color": "#4CAF50",
                "is_default": True,
                "sort_order": 1,
            },
            {
                "name": "Dịch vụ phòng",
                "name_en": "Room Service",
                "icon": "room_service",
                "color": "#2196F3",
                "is_default": False,
                "sort_order": 2,
            },
            {
                "name": "Minibar",
                "name_en": "Minibar",
                "icon": "liquor",
                "color": "#9C27B0",
                "is_default": False,
                "sort_order": 3,
            },
            {
                "name": "Giặt ủi",
                "name_en": "Laundry",
                "icon": "local_laundry_service",
                "color": "#00BCD4",
                "is_default": False,
                "sort_order": 4,
            },
            {
                "name": "Đặt cọc",
                "name_en": "Deposit",
                "icon": "savings",
                "color": "#FFC107",
                "is_default": False,
                "sort_order": 5,
            },
            {
                "name": "Phụ thu",
                "name_en": "Extra Charge",
                "icon": "add_circle",
                "color": "#FF9800",
                "is_default": False,
                "sort_order": 6,
            },
            {
                "name": "Phụ thu giờ",
                "name_en": "Hourly Surcharge",
                "icon": "schedule",
                "color": "#FF5722",
                "is_default": False,
                "sort_order": 7,
            },
            {
                "name": "Check-in sớm",
                "name_en": "Early Check-in",
                "icon": "login",
                "color": "#8BC34A",
                "is_default": False,
                "sort_order": 8,
            },
            {
                "name": "Check-out muộn",
                "name_en": "Late Check-out",
                "icon": "logout",
                "color": "#CDDC39",
                "is_default": False,
                "sort_order": 9,
            },
            {
                "name": "Thuê xe",
                "name_en": "Vehicle Rental",
                "icon": "directions_car",
                "color": "#03A9F4",
                "is_default": False,
                "sort_order": 10,
            },
            {
                "name": "Tour/Vé",
                "name_en": "Tours/Tickets",
                "icon": "confirmation_number",
                "color": "#E91E63",
                "is_default": False,
                "sort_order": 11,
            },
            {
                "name": "Khác (Thu)",
                "name_en": "Other (Income)",
                "icon": "more_horiz",
                "color": "#607D8B",
                "is_default": False,
                "sort_order": 99,
            },
        ]

        # Expense categories (matching Design Plan)
        expense_categories = [
            {
                "name": "Tiền điện",
                "name_en": "Electricity",
                "icon": "bolt",
                "color": "#F44336",
                "is_default": True,
                "sort_order": 1,
            },
            {
                "name": "Tiền nước",
                "name_en": "Water",
                "icon": "water_drop",
                "color": "#2196F3",
                "is_default": False,
                "sort_order": 2,
            },
            {
                "name": "Internet/TV",
                "name_en": "Internet/Cable TV",
                "icon": "wifi",
                "color": "#9C27B0",
                "is_default": False,
                "sort_order": 3,
            },
            {
                "name": "Vật tư phòng",
                "name_en": "Room Supplies",
                "icon": "inventory_2",
                "color": "#FF9800",
                "is_default": False,
                "sort_order": 4,
            },
            {
                "name": "Đồ dùng vệ sinh",
                "name_en": "Toiletries",
                "icon": "soap",
                "color": "#00BCD4",
                "is_default": False,
                "sort_order": 5,
            },
            {
                "name": "Sửa chữa/Bảo trì",
                "name_en": "Repair/Maintenance",
                "icon": "build",
                "color": "#795548",
                "is_default": False,
                "sort_order": 6,
            },
            {
                "name": "Lương nhân viên",
                "name_en": "Staff Wages",
                "icon": "people",
                "color": "#673AB7",
                "is_default": False,
                "sort_order": 7,
            },
            {
                "name": "Dọn dẹp",
                "name_en": "Cleaning Services",
                "icon": "cleaning_services",
                "color": "#4CAF50",
                "is_default": False,
                "sort_order": 8,
            },
            {
                "name": "Thực phẩm/Đồ uống",
                "name_en": "Food & Beverage",
                "icon": "restaurant",
                "color": "#E91E63",
                "is_default": False,
                "sort_order": 9,
            },
            {
                "name": "Thuế/Phí",
                "name_en": "Tax/Fees",
                "icon": "receipt_long",
                "color": "#3F51B5",
                "is_default": False,
                "sort_order": 10,
            },
            {
                "name": "Hoa hồng OTA",
                "name_en": "OTA Commission",
                "icon": "percent",
                "color": "#FF5722",
                "is_default": False,
                "sort_order": 11,
            },
            {
                "name": "Khác (Chi)",
                "name_en": "Other (Expense)",
                "icon": "more_horiz",
                "color": "#607D8B",
                "is_default": False,
                "sort_order": 99,
            },
        ]

        # Create income categories
        created_income = 0
        for cat_data in income_categories:
            cat, created = FinancialCategory.objects.get_or_create(
                name=cat_data["name"],
                category_type=FinancialCategory.CategoryType.INCOME,
                defaults={
                    "name_en": cat_data["name_en"],
                    "icon": cat_data["icon"],
                    "color": cat_data["color"],
                    "is_default": cat_data["is_default"],
                    "sort_order": cat_data["sort_order"],
                },
            )
            if created:
                created_income += 1
                self.stdout.write(f"  Created income category: {cat.name}")
            else:
                self.stdout.write(f"  Already exists: {cat.name}")

        # Create expense categories
        created_expense = 0
        for cat_data in expense_categories:
            cat, created = FinancialCategory.objects.get_or_create(
                name=cat_data["name"],
                category_type=FinancialCategory.CategoryType.EXPENSE,
                defaults={
                    "name_en": cat_data["name_en"],
                    "icon": cat_data["icon"],
                    "color": cat_data["color"],
                    "is_default": cat_data["is_default"],
                    "sort_order": cat_data["sort_order"],
                },
            )
            if created:
                created_expense += 1
                self.stdout.write(f"  Created expense category: {cat.name}")
            else:
                self.stdout.write(f"  Already exists: {cat.name}")

        self.stdout.write(
            self.style.SUCCESS(
                f"\nFinished! Created {created_income} income categories "
                f"and {created_expense} expense categories."
            )
        )
