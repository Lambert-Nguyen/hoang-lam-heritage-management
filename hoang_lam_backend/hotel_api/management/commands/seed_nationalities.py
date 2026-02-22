"""
Management command to seed common nationalities.
Usage: python manage.py seed_nationalities
"""

from django.core.management.base import BaseCommand

# Common nationalities for hotel guests
NATIONALITIES = [
    "Vietnam",
    "United States",
    "China",
    "Japan",
    "South Korea",
    "Singapore",
    "Thailand",
    "Malaysia",
    "Indonesia",
    "Philippines",
    "Australia",
    "United Kingdom",
    "France",
    "Germany",
    "Canada",
    "India",
    "Taiwan",
    "Hong Kong",
    "Russia",
    "Netherlands",
]


class Command(BaseCommand):
    """Seed common nationalities."""

    help = "Seed common nationalities for guest management"

    def handle(self, *args, **options):
        """Execute the command."""
        self.stdout.write(self.style.SUCCESS("Available nationalities:"))
        for nationality in NATIONALITIES:
            self.stdout.write(f"  - {nationality}")

        self.stdout.write(self.style.SUCCESS(f"\nTotal: {len(NATIONALITIES)} nationalities"))
        self.stdout.write(
            self.style.WARNING("\nNote: These nationalities are used for reference and validation.")
        )
