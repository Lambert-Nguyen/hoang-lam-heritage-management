"""
Management command to apply data retention policy.

Usage:
    python manage.py apply_retention_policy              # Apply all retention rules
    python manage.py apply_retention_policy --dry-run    # Preview without deleting
    python manage.py apply_retention_policy --model notification  # Only notifications
"""

from django.core.management.base import BaseCommand

from hotel_api.retention import DATA_RETENTION_DAYS, apply_retention_policy


class Command(BaseCommand):
    help = "Apply data retention policy — delete records past retention period"

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be deleted without making changes",
        )
        parser.add_argument(
            "--model",
            type=str,
            help=f"Only process a specific model. Options: {', '.join(sorted(DATA_RETENTION_DAYS.keys()))}",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        model_filter = options.get("model")

        if model_filter and model_filter not in DATA_RETENTION_DAYS:
            self.stderr.write(
                self.style.ERROR(
                    f"Unknown model: {model_filter}. "
                    f"Options: {', '.join(sorted(DATA_RETENTION_DAYS.keys()))}"
                )
            )
            return

        prefix = "[DRY RUN] " if dry_run else ""
        self.stdout.write(f"{prefix}Applying data retention policy...")

        results = apply_retention_policy(dry_run=dry_run, model_filter=model_filter)

        total = sum(results.values())
        for model_name, count in results.items():
            if count > 0:
                retention = DATA_RETENTION_DAYS[model_name]
                action = "Would delete" if dry_run else "Deleted"
                self.stdout.write(
                    f"  {action} {count} {model_name} record(s) " f"(retention: {retention} days)"
                )

        self.stdout.write(self.style.SUCCESS(f"{prefix}Done. Total: {total} record(s) affected."))
