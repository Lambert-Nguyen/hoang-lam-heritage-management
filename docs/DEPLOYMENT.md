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
| `DB_CONN_MAX_AGE` | No | `600` | Database connection lifetime in seconds. Set to `0` to disable persistent connections. See Section 12. |
| `SENTRY_DSN` | No | — | Sentry Data Source Name. Leave empty to disable Sentry. See Section 11. |
| `SENTRY_ENVIRONMENT` | No | `development` | Environment tag sent to Sentry. Falls back to `DJANGO_ENVIRONMENT`. |
| `SENTRY_TRACES_SAMPLE_RATE` | No | `0` | Sentry performance tracing rate (0.0–1.0). Use `0.1` in production. |
| `MEDIA_STORAGE_BACKEND` | No | `local` | Media storage backend. Set to `s3` for S3-compatible storage. See Section 13. |
| `AWS_STORAGE_BUCKET_NAME` | If S3 | — | S3 bucket name (only when `MEDIA_STORAGE_BACKEND=s3`). |
| `SMS_ENABLED` | No | `False` | Enable real SMS sending via eSMS.vn. See Section 14. |
| `SMS_API_KEY` | If SMS | — | eSMS.vn API key. |
| `SMS_SECRET_KEY` | If SMS | — | eSMS.vn secret key. |
| `SMS_BRAND_NAME` | If SMS | — | Registered brandname for SMS sender ID. |

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

---

## 11. Sentry Error Tracking

Sentry provides real-time error tracking, alerting, and performance monitoring. The integration is optional and disabled by default (no DSN = disabled).

### Setup

1. Create a project at [sentry.io](https://sentry.io) (or your self-hosted Sentry instance)
2. Copy the DSN from **Project Settings > Client Keys**
3. Add to `.env`:

```bash
SENTRY_DSN=https://your-key@o123456.ingest.sentry.io/1234567
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SENTRY_DSN` | (empty) | Sentry Data Source Name. Leave empty to disable. |
| `SENTRY_ENVIRONMENT` | `development` | Environment tag in Sentry (development/staging/production). Falls back to `DJANGO_ENVIRONMENT`. |
| `SENTRY_TRACES_SAMPLE_RATE` | `0` | Performance tracing sample rate (0.0 to 1.0). Set to `0.1` for 10% sampling in production. |

### What Gets Captured

Sentry automatically captures:

- **Unhandled exceptions** in Django views and middleware
- **DRF API errors** (500 Internal Server Error responses)
- **Celery task failures** (check-in reminders, checkout reminders, retention policy, token cleanup)
- **Python logging** errors (ERROR level and above)
- **Request context** (URL, method, headers — but NOT guest PII due to `send_default_pii=False`)

### Recommended Settings Per Environment

| Environment | `SENTRY_DSN` | `SENTRY_TRACES_SAMPLE_RATE` | Notes |
|-------------|-------------|---------------------------|-------|
| Development | (empty) | — | Sentry disabled |
| Staging | Set DSN | `1.0` | Capture everything for testing |
| Production | Set DSN | `0.1` | 10% sampling to save quota |

### Privacy

`send_default_pii` is set to `False` — Sentry will NOT capture:
- User IP addresses in breadcrumbs
- Request body data (guest CCCD, passport numbers)
- Cookies or session data

This ensures compliance with Vietnam data protection regulations.

---

## 12. Database Connection Pooling

By default, Django opens and closes a PostgreSQL connection for every request. Connection pooling keeps connections alive and reuses them, reducing overhead under load.

### Django Persistent Connections (Built-in)

Enabled by default in `base.py`:

| Setting | Value | Description |
|---------|-------|-------------|
| `CONN_MAX_AGE` | `600` (10 min) | How long a connection stays open for reuse. Set to `0` to disable. |
| `CONN_HEALTH_CHECKS` | `True` | Validates connections before reuse (Django 4.1+). Prevents stale connection errors. |

Override via environment variable:

```bash
DB_CONN_MAX_AGE=600   # seconds (0 = close after each request)
```

This is sufficient for most deployments with a single Django process (or a few Gunicorn workers).

### pgbouncer (Optional — Production Scaling)

For high-traffic deployments with many Gunicorn workers, pgbouncer acts as a connection multiplexer between Django and PostgreSQL. It is included in `docker-compose.yml` but disabled by default.

**Start with pgbouncer:**

```bash
docker compose --profile pooling up -d
```

**pgbouncer settings (docker-compose.yml):**

| Setting | Value | Description |
|---------|-------|-------------|
| `POOL_MODE` | `transaction` | Connections returned to pool after each transaction (Django-compatible). |
| `MAX_CLIENT_CONN` | `200` | Maximum client connections pgbouncer accepts. |
| `DEFAULT_POOL_SIZE` | `20` | Actual PostgreSQL connections maintained per database. |
| `MIN_POOL_SIZE` | `5` | Minimum idle connections kept open. |

**To route Django through pgbouncer**, update `.env`:

```bash
DB_HOST=pgbouncer   # instead of db
DB_PORT=6432        # pgbouncer port
DB_CONN_MAX_AGE=0   # let pgbouncer manage connection lifetime
```

> **Note:** When using pgbouncer in transaction mode, set `DB_CONN_MAX_AGE=0` on the Django side — pgbouncer handles connection reuse.

---

## 13. Media Storage

Uploaded files (guest ID photos, receipts, lost & found images) need to be served efficiently in production. Two backends are supported, switchable via `MEDIA_STORAGE_BACKEND` env var.

### Option A: Local Filesystem + Nginx (Default)

Files are stored on disk in `MEDIA_ROOT` and served by nginx. This is the default and works well for single-server VPS deployments.

**VPS deployment:** The nginx config in Section 2.7 already includes a `/media/` location block — no extra setup needed.

**Docker deployment:** Use the production profile to start nginx:

```bash
docker compose --profile production up -d
```

This starts an nginx container that serves `/media/` and `/static/` files, and proxies API requests to Django. The nginx config is at `nginx/default.conf`.

### Option B: S3-Compatible Storage (Cloud)

For cloud deployments or when you need CDN distribution, use S3-compatible storage (AWS S3, MinIO, DigitalOcean Spaces).

**Setup:**

```bash
# In .env
MEDIA_STORAGE_BACKEND=s3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=hoang-lam-media
AWS_S3_REGION_NAME=ap-southeast-1
```

**Optional S3 settings:**

| Variable | Default | Description |
|----------|---------|-------------|
| `MEDIA_STORAGE_BACKEND` | `local` | Set to `s3` for S3-compatible storage |
| `AWS_ACCESS_KEY_ID` | — | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | — | S3 secret key |
| `AWS_STORAGE_BUCKET_NAME` | — | S3 bucket name |
| `AWS_S3_REGION_NAME` | `ap-southeast-1` | AWS region |
| `AWS_S3_ENDPOINT_URL` | — | Custom endpoint for MinIO/DigitalOcean Spaces |
| `AWS_S3_CUSTOM_DOMAIN` | — | CloudFront/CDN domain for serving files |

**For DigitalOcean Spaces:**

```bash
MEDIA_STORAGE_BACKEND=s3
AWS_ACCESS_KEY_ID=your-spaces-key
AWS_SECRET_ACCESS_KEY=your-spaces-secret
AWS_STORAGE_BUCKET_NAME=hoang-lam-media
AWS_S3_REGION_NAME=sgp1
AWS_S3_ENDPOINT_URL=https://sgp1.digitaloceanspaces.com
```

### Security Notes

- **Signed URLs** (`AWS_QUERYSTRING_AUTH=True`): Guest ID photos and receipts are served via signed URLs that expire, preventing unauthorized access.
- **No file overwrite** (`AWS_S3_FILE_OVERWRITE=False`): Prevents accidental overwriting of existing files.
- **5 MB upload limit**: Enforced by both Django (`FILE_UPLOAD_MAX_MEMORY_SIZE`) and nginx (`client_max_body_size`).
- **Image validation**: All ImageFields use `validate_image_file()` — max 5 MB, allowed types: jpg, jpeg, png, gif, webp.

---

## 14. SMS Gateway (eSMS.vn)

Guest SMS messaging uses [eSMS.vn](https://esms.vn) as the SMS gateway. SMS is disabled by default in development (returns mock responses).

### Setup

1. Register at [esms.vn](https://esms.vn) and get your API credentials
2. Register a brandname (e.g., `HOANGLAM`) — required for customer care SMS in Vietnam
3. Add to `.env`:

```bash
SMS_ENABLED=True
SMS_API_KEY=your-api-key
SMS_SECRET_KEY=your-secret-key
SMS_BRAND_NAME=HOANGLAM
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SMS_ENABLED` | `False` | Enable real SMS sending. When `False`, logs messages without sending. |
| `SMS_API_KEY` | — | eSMS.vn API key from dashboard |
| `SMS_SECRET_KEY` | — | eSMS.vn secret key from dashboard |
| `SMS_BRAND_NAME` | — | Registered brandname for SMS sender ID |

### How It Works

- Staff sends SMS from the Flutter app via `POST /api/v1/guest-messages/send/`
- Backend routes to `SMSService.send()` → eSMS.vn REST API
- Message templates support variables: `{guest_name}`, `{room_number}`, `{check_in_date}`, etc.
- Delivery status tracked in `GuestMessage` model (pending → sent/failed)
- 4 default templates seeded: booking confirmation, pre-arrival info, checkout reminder, review request

### eSMS API Details

- **Endpoint**: `https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post`
- **SmsType**: `2` (customer care / CSKH — not advertising)
- **Success code**: `CodeResult == "100"`
- **Timeout**: 30 seconds
- **Error handling**: HTTP errors, timeouts, and API error codes are all captured in `GuestMessage.send_error`

### Testing

In development (`SMS_ENABLED=False`), SMS calls return mock success responses and log the message content. This allows full testing of the messaging flow without sending real SMS.

To test with real SMS (staging):

```bash
SMS_ENABLED=True SMS_API_KEY=your-key SMS_SECRET_KEY=your-secret SMS_BRAND_NAME=HOANGLAM \
  python manage.py shell -c "
from hotel_api.messaging_service import SMSService
result = SMSService.send('0912345678', 'Test từ Hoàng Lâm Heritage')
print(result)
"
```
