"""
One-time management command to encrypt existing guest sensitive data.

Run this after setting FIELD_ENCRYPTION_KEY in .env:
    python manage.py encrypt_guest_data

This command is idempotent — already-encrypted values are skipped.
"""

from django.core.management.base import BaseCommand

from hotel_api.encryption import encrypt, hash_value, is_encrypted
from hotel_api.models import Guest


class Command(BaseCommand):
    help = "Encrypt existing guest id_number and visa_number fields"

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be encrypted without making changes",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        guests = Guest.objects.all()
        total = guests.count()
        encrypted_count = 0
        skipped_count = 0

        self.stdout.write(f"Processing {total} guest(s)...")

        for guest in guests.iterator():
            changed = False

            if guest.id_number and not is_encrypted(guest.id_number):
                if not dry_run:
                    guest.id_number_hash = hash_value(guest.id_number)
                    guest.id_number = encrypt(guest.id_number)
                    changed = True
                else:
                    self.stdout.write(f"  Would encrypt id_number for guest {guest.id} ({guest.full_name})")
            elif guest.id_number:
                skipped_count += 1

            if guest.visa_number and not is_encrypted(guest.visa_number):
                if not dry_run:
                    guest.visa_number_hash = hash_value(guest.visa_number)
                    guest.visa_number = encrypt(guest.visa_number)
                    changed = True
                else:
                    self.stdout.write(f"  Would encrypt visa_number for guest {guest.id} ({guest.full_name})")

            if changed:
                # Use update_fields to avoid triggering save() encryption again
                Guest.objects.filter(pk=guest.pk).update(
                    id_number=guest.id_number,
                    id_number_hash=guest.id_number_hash,
                    visa_number=guest.visa_number,
                    visa_number_hash=guest.visa_number_hash,
                )
                encrypted_count += 1

        prefix = "[DRY RUN] " if dry_run else ""
        self.stdout.write(
            self.style.SUCCESS(
                f"{prefix}Done. Encrypted: {encrypted_count}, Skipped (already encrypted): {skipped_count}, Total: {total}"
            )
        )
