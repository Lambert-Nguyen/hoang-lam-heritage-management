# Deployment Guide — Hoang Lam Heritage Management

## Prerequisites

| Component | Version | Purpose |
|-----------|---------|---------|
| Python | 3.11+ | Django backend runtime |
| PostgreSQL | 15+ | Primary database |
| Redis | 7+ | Celery broker, caching |
| Nginx | latest | Reverse proxy, static files |
| Flutter | 3.x | Mobile app builds |
| Node.js | 18+ (optional) | Frontend tooling |

---

## 1. Quick Start (Docker)

The fastest way to get the backend running:

```bash
# Clone the repository
git clone <repo-url>
cd hoang-lam-heritage-management

# Copy environment file
cp hoang_lam_backend/.env.example hoang_lam_backend/.env
# Edit .env with your values (see Environment Variables section below)

# Start all services
docker compose up -d

# Services started:
#   web          → Django on http://localhost:8000
#   db           → PostgreSQL on port 5432
#   redis        → Redis on port 6379
#   celery-worker → Celery task worker
#   celery-beat   → Celery scheduler

# Seed initial data (optional)
docker compose exec web python manage.py create_admin_users
docker compose exec web python manage.py seed_room_types
docker compose exec web python manage.py seed_rooms
```

---

## 2. Manual Deployment (VPS)

### 2.1 System Setup

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3.11 python3.11-venv python3-pip \
    postgresql postgresql-contrib redis-server nginx \
    certbot python3-certbot-nginx git

# Verify installations
python3.11 --version
psql --version
redis-cli ping
nginx -v
```

### 2.2 PostgreSQL Setup

```bash
sudo -u postgres psql <<EOF
CREATE USER hoang_lam WITH PASSWORD 'your-secure-password';
CREATE DATABASE hoang_lam_heritage OWNER hoang_lam;
GRANT ALL PRIVILEGES ON DATABASE hoang_lam_heritage TO hoang_lam;
EOF
```

### 2.3 Application Setup

```bash
# Create app user
sudo useradd -m -s /bin/bash hoanglam
sudo su - hoanglam

# Clone and set up
git clone <repo-url> ~/app
cd ~/app/hoang_lam_backend

# Create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn

# Configure environment
cp .env.example .env
# Edit .env — see Environment Variables section below
```

### 2.4 Django Setup

```bash
cd ~/app/hoang_lam_backend
source .venv/bin/activate

# Set production settings
export DJANGO_SETTINGS_MODULE=backend.settings.production

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser

# Seed data (first deployment only)
python manage.py seed_room_types
python manage.py seed_rooms
python manage.py seed_financial_categories
python manage.py seed_nationalities
python manage.py seed_message_templates
```

### 2.5 Gunicorn (WSGI Server)

Create systemd service at `/etc/systemd/system/hoanglam-web.service`:

```ini
[Unit]
Description=Hoang Lam Django (Gunicorn)
After=network.target postgresql.service redis.service

[Service]
User=hoanglam
Group=hoanglam
WorkingDirectory=/home/hoanglam/app/hoang_lam_backend
Environment="DJANGO_SETTINGS_MODULE=backend.settings.production"
ExecStart=/home/hoanglam/app/hoang_lam_backend/.venv/bin/gunicorn \
    backend.wsgi:application \
    --bind unix:/run/hoanglam/gunicorn.sock \
    --workers 3 \
    --timeout 120 \
    --access-logfile /home/hoanglam/app/hoang_lam_backend/logs/gunicorn_access.log \
    --error-logfile /home/hoanglam/app/hoang_lam_backend/logs/gunicorn_error.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo mkdir -p /run/hoanglam
sudo chown hoanglam:hoanglam /run/hoanglam
sudo systemctl daemon-reload
sudo systemctl enable --now hoanglam-web
```

### 2.6 Celery Worker & Beat

Create `/etc/systemd/system/hoanglam-celery.service`:

```ini
[Unit]
Description=Hoang Lam Celery Worker
After=network.target redis.service

[Service]
User=hoanglam
Group=hoanglam
WorkingDirectory=/home/hoanglam/app/hoang_lam_backend
Environment="DJANGO_SETTINGS_MODULE=backend.settings.production"
ExecStart=/home/hoanglam/app/hoang_lam_backend/.venv/bin/celery \
    -A backend worker -l info \
    --logfile=/home/hoanglam/app/hoang_lam_backend/logs/celery_worker.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/hoanglam-celery-beat.service`:

```ini
[Unit]
Description=Hoang Lam Celery Beat (Scheduler)
After=network.target redis.service

[Service]
User=hoanglam
Group=hoanglam
WorkingDirectory=/home/hoanglam/app/hoang_lam_backend
Environment="DJANGO_SETTINGS_MODULE=backend.settings.production"
ExecStart=/home/hoanglam/app/hoang_lam_backend/.venv/bin/celery \
    -A backend beat -l info \
    --logfile=/home/hoanglam/app/hoang_lam_backend/logs/celery_beat.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hoanglam-celery hoanglam-celery-beat
```

### 2.7 Nginx Reverse Proxy

Create `/etc/nginx/sites-available/hoanglam`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Max upload size (matches Django's 5MB setting)
    client_max_body_size 5M;

    # Static files
    location /static/ {
        alias /home/hoanglam/app/hoang_lam_backend/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files (user uploads)
    location /media/ {
        alias /home/hoanglam/app/hoang_lam_backend/media/;
        expires 7d;
    }

    # API & Admin
    location / {
        proxy_pass http://unix:/run/hoanglam/gunicorn.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/hoanglam /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# SSL certificate
sudo certbot --nginx -d your-domain.com
```

---

## 3. Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DJANGO_SECRET_KEY` | **Yes** | — | Generate with `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"` |
| `DEBUG` | No | `True` | Set to `False` in production |
| `ALLOWED_HOSTS` | **Yes** | `localhost` | Comma-separated hostnames, e.g. `your-domain.com,www.your-domain.com` |
| `DJANGO_SETTINGS_MODULE` | **Yes** | — | `backend.settings.production` for prod |
| `DB_NAME` | **Yes** | `hoang_lam_heritage` | PostgreSQL database name |
| `DB_USER` | **Yes** | `postgres` | PostgreSQL username |
| `DB_PASSWORD` | **Yes** | — | PostgreSQL password |
| `DB_HOST` | No | `localhost` | Database host |
| `DB_PORT` | No | `5432` | Database port |
| `CELERY_BROKER_URL` | No | `redis://localhost:6379/0` | Redis URL for Celery |
| `CELERY_RESULT_BACKEND` | No | `redis://localhost:6379/0` | Redis URL for results |
| `REDIS_URL` | No | — | Redis URL for Django caching |
| `CORS_ALLOWED_ORIGINS` | No | `http://localhost:3000` | Allowed CORS origins |
| `FIELD_ENCRYPTION_KEY` | **Yes (prod)** | — | Fernet key for encrypting guest ID/passport data. Generate: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`. Leave empty to disable encryption (dev/test). |
| `DATA_RETENTION_OVERRIDES` | No | — | Override default retention periods. Format: `model=days,model=days` (e.g., `notification=60,booking=1825`). See Section 9. |
| `FCM_ENABLED` | No | `False` | Enable push notifications |
| `FCM_CREDENTIALS_FILE` | No | — | Path to Firebase credentials JSON |
| `FCM_CREDENTIALS_JSON` | No | — | Firebase credentials as JSON string |
| `EMAIL_HOST` | No | `smtp.gmail.com` | SMTP server |
| `EMAIL_PORT` | No | `587` | SMTP port |
| `EMAIL_HOST_USER` | No | — | SMTP username |
| `EMAIL_HOST_PASSWORD` | No | — | SMTP password |
| `DEFAULT_FROM_EMAIL` | No | `noreply@hoanglam.com` | Sender email address |
| `ADMIN_EMAIL` | No | `admin@hoanglam.com` | Admin notification email |

---

## 4. Database Management

### Backup

```bash
# Full backup
pg_dump -U hoang_lam -h localhost hoang_lam_heritage > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
pg_dump -U hoang_lam -h localhost -Fc hoang_lam_heritage > backup_$(date +%Y%m%d).dump

# Automated daily backup (add to crontab)
# 0 3 * * * pg_dump -U hoang_lam -Fc hoang_lam_heritage > /backups/db_$(date +\%Y\%m\%d).dump
```

### Restore

```bash
# From SQL file
psql -U hoang_lam -h localhost hoang_lam_heritage < backup.sql

# From compressed dump
pg_restore -U hoang_lam -h localhost -d hoang_lam_heritage backup.dump
```

### Migrations

```bash
cd ~/app/hoang_lam_backend
source .venv/bin/activate

# Check for pending migrations
python manage.py showmigrations | grep '\[ \]'

# Apply migrations
python manage.py migrate

# Create new migration after model changes
python manage.py makemigrations hotel_api
```

---

## 5. Monitoring & Logs

### Log Locations

| Service | Log Path |
|---------|----------|
| Django (production) | `hoang_lam_backend/logs/production.log` |
| Django errors | `hoang_lam_backend/logs/production_errors.log` |
| Security audit log | `hoang_lam_backend/logs/security_audit.log` |
| Gunicorn access | `hoang_lam_backend/logs/gunicorn_access.log` |
| Gunicorn errors | `hoang_lam_backend/logs/gunicorn_error.log` |
| Celery worker | `hoang_lam_backend/logs/celery_worker.log` |
| Celery beat | `hoang_lam_backend/logs/celery_beat.log` |
| Nginx access | `/var/log/nginx/access.log` |
| Nginx errors | `/var/log/nginx/error.log` |

### Health Check

The API schema endpoint can serve as a basic health check:

```bash
curl -s https://your-domain.com/api/schema/ -o /dev/null -w "%{http_code}"
# Should return 200
```

### Service Status

```bash
sudo systemctl status hoanglam-web
sudo systemctl status hoanglam-celery
sudo systemctl status hoanglam-celery-beat
sudo systemctl status postgresql
sudo systemctl status redis
sudo systemctl status nginx
```

---

## 6. Flutter App (Release Builds)

### Android

```bash
cd hoang_lam_app

# Update API base URL in lib/core/config/app_config.dart
# Set to your production domain

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
cd hoang_lam_app

# Build for iOS
flutter build ios --release

# Open in Xcode for archive & distribution
open ios/Runner.xcworkspace
# Xcode → Product → Archive → Distribute App
```

---

## 7. Updating (Zero-Downtime)

```bash
cd ~/app
git pull origin main

cd hoang_lam_backend
source .venv/bin/activate
pip install -r requirements.txt

export DJANGO_SETTINGS_MODULE=backend.settings.production
python manage.py migrate
python manage.py collectstatic --noinput

# Graceful restart
sudo systemctl restart hoanglam-web
sudo systemctl restart hoanglam-celery
sudo systemctl restart hoanglam-celery-beat
```

---

## 8. Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `502 Bad Gateway` | Gunicorn not running or socket missing | `sudo systemctl restart hoanglam-web` and check logs |
| `ALLOWED_HOSTS` error | Domain not in env var | Add domain to `ALLOWED_HOSTS` in `.env` |
| Database connection refused | PostgreSQL not running or wrong credentials | Check `systemctl status postgresql`, verify `.env` DB vars |
| Celery tasks not executing | Worker not running or Redis down | `systemctl status hoanglam-celery`, `redis-cli ping` |
| Static files 404 | `collectstatic` not run | `python manage.py collectstatic --noinput` |
| SSL certificate expired | Certbot auto-renewal failed | `sudo certbot renew --force-renewal` |
| Push notifications not sent | FCM not configured | Set `FCM_ENABLED=True` and provide credentials in `.env` |
| Migrations fail | Database state mismatch | Check `python manage.py showmigrations`, resolve conflicts |
| Retention task not running | Celery Beat not started or schedule missing | Check `systemctl status hoanglam-celery-beat`, verify `CELERY_BEAT_SCHEDULE` in settings |
| Encrypted fields unreadable | `FIELD_ENCRYPTION_KEY` changed or missing | Restore the original key from backup. Never rotate keys without re-encrypting data first. |

---

## 9. Data Retention Policy

The system automatically deletes old records based on configurable retention periods. This ensures database performance, compliance with Vietnam data protection regulations, and reduced storage costs.

### Retention Periods

| Data Category | Retention | Date Field | Conditions |
|---------------|-----------|------------|------------|
| Notifications | 90 days | `created_at` | All notifications |
| Device tokens (inactive) | 30 days | `updated_at` | Only `is_active=False` tokens |
| Housekeeping tasks | 1 year | `created_at` | Only `completed` or `verified` status |
| Room inspections | 1 year | `created_at` | Only completed inspections |
| Guest messages | 2 years | `created_at` | All messages |
| Maintenance requests | 2 years | `created_at` | Only `completed` or `cancelled` status |
| Lost & found | 2 years | `created_at` | Only `disposed` status |
| Bookings | 3 years | `check_out_date` | Only `checked_out`, `cancelled`, or `no_show` status |
| Payments, folio items, minibar sales | 3 years | — | Cascade-deleted with their booking |
| Exchange rates | 3 years | `date` | All rates |
| Date rate overrides | 3 years | `date` | All overrides |
| Night audits | 5 years | `audit_date` | Only `closed` status |
| Financial entries | 5 years | `date` | Only entries not linked to a booking |
| Sensitive data access logs | 7 years | `timestamp` | Legal compliance requirement |

**Records NOT subject to retention:**
- Guest profiles (kept indefinitely for returning customers)
- Master data: rooms, room types, rate plans, minibar items, financial categories, message templates
- Active bookings (`pending`, `confirmed`, `checked_in`)
- Users and hotel profiles

### Automatic Execution

The retention policy runs automatically via Celery Beat:

- **Schedule**: Every Sunday at 3:00 AM (Vietnam time)
- **Task**: `hotel_api.tasks.apply_data_retention_policy`
- **Logging**: All deletions are logged to `hotel_api` logger

### Manual Execution

```bash
cd hoang_lam_backend
source .venv/bin/activate

# Preview what would be deleted (no actual deletions)
python manage.py apply_retention_policy --dry-run

# Apply retention policy
python manage.py apply_retention_policy

# Apply only for a specific model
python manage.py apply_retention_policy --model notification
python manage.py apply_retention_policy --model booking --dry-run
```

Available model names for `--model` filter: `booking`, `date_rate_override`, `device_token`, `exchange_rate`, `financial_entry`, `guest_message`, `housekeeping_task`, `lost_and_found`, `maintenance_request`, `night_audit`, `notification`, `room_inspection`, `sensitive_data_access_log`.

### Customizing Retention Periods

Override default retention periods via the `DATA_RETENTION_OVERRIDES` environment variable:

```bash
# In .env — set notifications to 60 days, bookings to 5 years (1825 days)
DATA_RETENTION_OVERRIDES=notification=60,booking=1825
```

Format: comma-separated `model_name=days` pairs.

### Cascade Behavior

When a booking is deleted by the retention policy, the following related records are automatically deleted (via database CASCADE):

- **Payments** linked to the booking
- **Folio items** linked to the booking
- **Minibar sales** linked to the booking
- **Housekeeping tasks** linked to the booking (via `SET_NULL` — the task remains but loses its booking reference)
- **Notifications** linked to the booking (via `SET_NULL`)
- **Financial entries** linked to the booking (via `SET_NULL`)

---

## 10. Sensitive Data Encryption

Guest identity data (`id_number` / CCCD and `visa_number`) is encrypted at rest using Fernet symmetric encryption (AES-128-CBC + HMAC-SHA256).

### Setup

1. Generate an encryption key:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

2. Add to `.env`:

```bash
FIELD_ENCRYPTION_KEY=your-generated-key-here
```

3. Encrypt existing data (one-time, after setting the key):

```bash
cd hoang_lam_backend
source .venv/bin/activate

# Preview
python manage.py encrypt_guest_data --dry-run

# Encrypt
python manage.py encrypt_guest_data
```

### How It Works

- **On save**: Guest `id_number` and `visa_number` are automatically encrypted. A SHA-256 hash is stored in `id_number_hash` / `visa_number_hash` for searchability.
- **On read**: The API serializer automatically decrypts values before returning them to the client.
- **Search**: Searching by ID number uses exact hash matching (not partial/fuzzy search).
- **Disabled by default**: If `FIELD_ENCRYPTION_KEY` is empty, fields are stored as plaintext (for development/testing).

### Key Management

- **Never lose the key.** If the encryption key is lost, encrypted data cannot be recovered.
- **Back up the key** separately from the database backup.
- **Key rotation** is not currently supported — to rotate, you must decrypt all data with the old key, then re-encrypt with the new key.

### Audit Logging

All access to guest sensitive data is logged in the `SensitiveDataAccessLog` table:

| Field | Description |
|-------|-------------|
| `user` | Staff member who accessed the data |
| `action` | What they did: `view_guest`, `list_guests`, `search_guest`, `create_guest`, `update_guest`, `view_guest_history`, `export_declaration`, `export_receipt` |
| `resource_id` | Guest ID accessed |
| `ip_address` | Client IP address |
| `user_agent` | Browser/app user agent |
| `fields_accessed` | Which sensitive fields were accessed |
| `timestamp` | When the access occurred |

View audit logs in Django admin at `/admin/hotel_api/sensitivedataaccesslog/` (read-only).

In production, audit entries are also written to `logs/security_audit.log` (rotating, 50 MB max, 10 backups).
