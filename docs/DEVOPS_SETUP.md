# DevOps Setup Documentation

## CI/CD Configuration

### GitHub Actions Workflows

The project includes several automated workflows:

#### 1. Backend CI (`backend-ci.yml`)
- **Triggers**: Push/PR to main/develop branches
- **Jobs**:
  - **Lint**: Runs black, isort, and flake8
  - **Test**: Runs pytest with PostgreSQL, generates coverage reports
  - **Django Check**: System checks and migration validation

#### 2. Flutter CI (`flutter-ci.yml`)
- **Triggers**: Push/PR to main/develop branches
- **Jobs**:
  - **Analyze**: Format check and static analysis
  - **Test**: Unit tests with coverage
  - **Build Android**: Debug APK build
  - **Build iOS**: iOS build without code signing

#### 3. Security Scanning (`security.yml`)
- **Triggers**: Push/PR + weekly schedule (Monday 9 AM)
- **Jobs**:
  - **Python Security**: Bandit (SAST) and Safety (dependency vulnerabilities)
  - **Dependency Review**: GitHub dependency scanning
  - **CodeQL**: Advanced security analysis
  - **Secret Scan**: TruffleHog for exposed secrets

### Required GitHub Secrets

Configure these secrets in GitHub Settings > Secrets and variables > Actions:

1. **`CODECOV_TOKEN`** (Required for coverage reports)
   - Sign up at [codecov.io](https://codecov.io)
   - Add your repository
   - Copy the upload token
   - Add as repository secret: `CODECOV_TOKEN`

2. **Optional Secrets** (for production deployment):
   - `DJANGO_SECRET_KEY`: Production Django secret key
   - `DATABASE_URL`: Production PostgreSQL connection string
   - `AWS_ACCESS_KEY_ID`: For AWS deployments
   - `AWS_SECRET_ACCESS_KEY`: For AWS deployments

### Codecov Configuration

Coverage tracking is configured in `codecov.yml`:
- **Target Coverage**: 70% minimum
- **Threshold**: 2% for project, 5% for patches
- **Ignored Files**: Migrations, tests, generated files
- **Flags**: Separate tracking for backend and flutter

## Code Quality Tools

### Pre-commit Hooks

Automated checks run before each commit:

```bash
# Install hooks (one-time setup)
make pre-commit-install

# Run manually on all files
make pre-commit-run
```

**Hooks included**:
- Trailing whitespace removal
- YAML/JSON/TOML validation
- Large file detection
- Private key detection
- Black formatting (Python)
- isort import sorting (Python)
- Flake8 linting (Python)
- Django system checks
- Django migrations check

### Linting Configuration

#### Python (Backend)
- **Black**: Code formatter (100 char line length)
  - Config: `hoang_lam_backend/pyproject.toml`
- **isort**: Import sorter (black-compatible)
  - Config: `hoang_lam_backend/pyproject.toml`
- **Flake8**: Style guide enforcement
  - Config: `hoang_lam_backend/.flake8`
  - Max complexity: 10
  - Plugins: flake8-docstrings, flake8-bugbear

#### Flutter/Dart
- **dart format**: Official formatter (80 char line length)
- **flutter analyze**: Static analysis with fatal-infos and fatal-warnings

### EditorConfig

Cross-editor consistency configuration (`.editorconfig`):
- Python: 4 spaces, 100 char line length
- Dart: 2 spaces, 80 char line length
- YAML/JSON: 2 spaces
- Unix line endings (LF) for all files

## Dependency Management

### Dependabot

Automated dependency updates configured in `.github/dependabot.yml`:

- **Python (Backend)**: Weekly updates on Monday 9 AM
- **Flutter/Dart**: Weekly updates on Monday 9 AM
- **GitHub Actions**: Monthly updates
- **Docker**: Monthly updates

**Features**:
- Auto-labels PRs by type (backend, flutter, ci-cd)
- Conventional commit messages
- Ignores major version updates for Django/DRF

### Manual Updates

```bash
# Backend dependencies
cd hoang_lam_backend
pip list --outdated
pip install -r requirements.txt -r requirements-dev.txt --upgrade

# Flutter dependencies
cd hoang_lam_app
flutter pub outdated
flutter pub upgrade
```

## Makefile Commands

Comprehensive development commands:

### Backend
```bash
make backend-install          # Install dependencies
make backend-migrate          # Run migrations
make backend-run              # Start development server
make backend-test             # Run tests
make backend-test-coverage    # Tests with HTML coverage report
make backend-lint             # Run all linting checks
make backend-format           # Auto-format code
make backend-shell            # Open Django shell
make backend-createsuperuser  # Create admin user
make backend-clean            # Clean cache files
```

### Flutter
```bash
make flutter-install     # Get dependencies
make flutter-run         # Run app
make flutter-build       # Build APK
make flutter-test        # Run tests
make flutter-analyze     # Static analysis
make flutter-format      # Format code
make flutter-clean       # Clean build artifacts
```

### Docker
```bash
make docker-up      # Start containers
make docker-down    # Stop containers
make docker-logs    # View logs
make docker-clean   # Remove containers and volumes
```

### Combined
```bash
make install       # Install all dependencies
make test          # Run all tests
make lint          # Run all linting
make format        # Format all code
make clean         # Clean all caches
make dev-setup     # Complete development setup
make help          # Show all commands
```

## GitHub Features

### Issue Templates

Two templates available when creating issues:
1. **Bug Report**: Structured bug reporting with environment details
2. **Feature Request**: Feature proposals with user stories and acceptance criteria

Location: `.github/ISSUE_TEMPLATE/`

### Pull Request Template

Comprehensive PR template (`.github/pull_request_template.md`):
- Type of change checkboxes
- Testing checklist
- Documentation updates
- Code review guidelines

### CODEOWNERS

Automatic reviewer assignment (`.github/CODEOWNERS`):
- Backend changes: @duylam1407
- Frontend changes: @duylam1407
- Infrastructure changes: @duylam1407
- Documentation changes: @duylam1407

## Security Best Practices

### Implemented Security Measures

1. **Automated Security Scanning**:
   - Bandit: Python SAST
   - Safety: Dependency vulnerability scanning
   - CodeQL: Advanced code analysis
   - TruffleHog: Secret detection

2. **Dependency Updates**:
   - Dependabot: Automated dependency PRs
   - Dependency Review: PR-based vulnerability checks

3. **Code Quality**:
   - Pre-commit hooks prevent bad commits
   - Linting enforces secure coding patterns
   - Type checking (future: mypy integration)

4. **Django Security**:
   - `--deploy` flag in system checks
   - Migration drift detection
   - Secret key validation
   - Security middleware enabled

### Manual Security Checks

```bash
# Run security scans locally
cd hoang_lam_backend
pip install bandit safety

# SAST scan
bandit -r . -ll

# Dependency vulnerabilities
safety check

# Django security check
DJANGO_SETTINGS_MODULE=backend.settings.production python manage.py check --deploy
```

## Troubleshooting

### Pre-commit Hook Failures

```bash
# Update hooks to latest versions
pre-commit autoupdate

# Clear hook cache
pre-commit clean

# Re-install hooks
pre-commit install --install-hooks
```

### CI/CD Failures

1. **Linting failures**: Run `make backend-format` locally before pushing
2. **Test failures**: Run `make backend-test` locally to reproduce
3. **Coverage drops**: Add tests for new code (target: 70%)
4. **Dependency conflicts**: Check Dependabot PRs and resolve manually

### Coverage Upload Issues

If Codecov uploads fail:
1. Verify `CODECOV_TOKEN` is set in GitHub secrets
2. Check codecov.yml syntax: `yamllint codecov.yml`
3. Review workflow logs for upload errors
4. Token permissions: Ensure token has write access

## Next Steps

After Phase 0.3 completion:
1. ✅ All DevOps infrastructure is in place
2. ✅ CI/CD pipelines are automated
3. ✅ Code quality tools are configured
4. ✅ Security scanning is enabled
5. 🚀 Ready to start Phase 1 (Core MVP Development)

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Pre-commit Hooks](https://pre-commit.com/)
- [Codecov Documentation](https://docs.codecov.com/)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
