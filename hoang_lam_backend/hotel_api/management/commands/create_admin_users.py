"""
Management command to create initial admin users for Hoang Lam Heritage.

Creates two admin accounts:
1. Mom (Owner): hoang_lam_owner
2. Brother (Manager): hoang_lam_manager
"""

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction

from hotel_api.models import HotelUser

User = get_user_model()


class Command(BaseCommand):
    help = "Create initial admin users (owner and manager) for Hoang Lam Heritage"

    def add_arguments(self, parser):
        parser.add_argument(
            "--skip-if-exists",
            action="store_true",
            help="Skip creation if users already exist",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        skip_if_exists = options.get("skip_if_exists", False)

        # Owner account (Mom)
        owner_data = {
            "username": "hoang_lam_owner",
            "email": "owner@hoanglam.vn",
            "first_name": "Chủ",
            "last_name": "Khách Sạn",
            "password": "HoangLam2026!Owner",  # Should be changed on first login
        }
        owner_profile = {"role": "owner", "phone": "0987654321"}

        # Manager account (Brother)
        manager_data = {
            "username": "hoang_lam_manager",
            "email": "manager@hoanglam.vn",
            "first_name": "Quản",
            "last_name": "Lý",
            "password": "HoangLam2026!Manager",  # Should be changed on first login
        }
        manager_profile = {"role": "manager", "phone": "0987654322"}

        users_created = 0
        users_skipped = 0

        # Create owner
        if User.objects.filter(username=owner_data["username"]).exists():
            if skip_if_exists:
                self.stdout.write(
                    self.style.WARNING(
                        f"Owner user '{owner_data['username']}' already exists. Skipping."
                    )
                )
                users_skipped += 1
            else:
                self.stdout.write(
                    self.style.ERROR(
                        f"Owner user '{owner_data['username']}' already exists. Use --skip-if-exists to skip."
                    )
                )
        else:
            owner_user = User.objects.create_user(
                username=owner_data["username"],
                email=owner_data["email"],
                password=owner_data["password"],
                first_name=owner_data["first_name"],
                last_name=owner_data["last_name"],
                is_staff=True,
                is_superuser=True,
            )
            HotelUser.objects.create(
                user=owner_user, role=owner_profile["role"], phone=owner_profile["phone"]
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f"✓ Created owner account: {owner_data['username']} (password: {owner_data['password']})"
                )
            )
            users_created += 1

        # Create manager
        if User.objects.filter(username=manager_data["username"]).exists():
            if skip_if_exists:
                self.stdout.write(
                    self.style.WARNING(
                        f"Manager user '{manager_data['username']}' already exists. Skipping."
                    )
                )
                users_skipped += 1
            else:
                self.stdout.write(
                    self.style.ERROR(
                        f"Manager user '{manager_data['username']}' already exists. Use --skip-if-exists to skip."
                    )
                )
        else:
            manager_user = User.objects.create_user(
                username=manager_data["username"],
                email=manager_data["email"],
                password=manager_data["password"],
                first_name=manager_data["first_name"],
                last_name=manager_data["last_name"],
                is_staff=True,
            )
            HotelUser.objects.create(
                user=manager_user, role=manager_profile["role"], phone=manager_profile["phone"]
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f"✓ Created manager account: {manager_data['username']} (password: {manager_data['password']})"
                )
            )
            users_created += 1

        # Summary
        self.stdout.write("\n" + "=" * 60)
        self.stdout.write(self.style.SUCCESS(f"✓ Admin user creation complete!"))
        self.stdout.write(f"  - Created: {users_created}")
        self.stdout.write(f"  - Skipped: {users_skipped}")

        if users_created > 0:
            self.stdout.write(
                "\n"
                + self.style.WARNING("⚠ IMPORTANT: Change these default passwords immediately!")
            )
            self.stdout.write("\n" + "Login credentials:")
            self.stdout.write("  Owner:   hoang_lam_owner / HoangLam2026!Owner")
            self.stdout.write("  Manager: hoang_lam_manager / HoangLam2026!Manager")
        self.stdout.write("=" * 60)
