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
