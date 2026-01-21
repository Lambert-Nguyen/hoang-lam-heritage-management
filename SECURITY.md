# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: [your-email@domain.com]

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Security Measures

This project implements multiple security layers:

### 1. Automated Security Scanning

- **Bandit**: Static Application Security Testing (SAST) for Python
- **Safety**: Dependency vulnerability scanning
- **CodeQL**: Advanced semantic code analysis
- **TruffleHog**: Secret detection in git history
- **Dependabot**: Automated dependency security updates

### 2. Code Quality & Review

- Pre-commit hooks enforce secure coding practices
- Pull request reviews required before merging
- Automated linting catches common security issues
- Type checking (future enhancement with mypy)

### 3. Django Security Configuration

- Security middleware enabled in all environments
- HTTPS enforcement in production
- Secure cookie settings (HttpOnly, Secure, SameSite)
- CSRF protection enabled
- SQL injection protection via ORM
- XSS protection via template engine
- Clickjacking protection
- Content Security Policy headers

### 4. Authentication & Authorization

- JWT-based authentication with SimpleJWT
- Role-based access control (RBAC)
- Password validation requirements
- Token expiration and refresh mechanisms
- Rate limiting on authentication endpoints

### 5. Infrastructure Security

- Environment-based configuration (dev/staging/production)
- Secrets management via environment variables
- Database connection encryption
- CORS policy enforcement
- Docker security best practices

## Security Best Practices for Developers

### Environment Variables

Never commit sensitive data:
```bash
# ❌ BAD
DATABASE_URL = "postgres://user:password@localhost/db"

# ✅ GOOD
DATABASE_URL = os.getenv('DATABASE_URL')
```

### SQL Queries

Always use Django ORM or parameterized queries:
```python
# ❌ BAD - SQL injection vulnerable
User.objects.raw(f"SELECT * FROM users WHERE name = '{user_input}'")

# ✅ GOOD - Safe parameterized query
User.objects.raw("SELECT * FROM users WHERE name = %s", [user_input])

# ✅ BEST - Use ORM
User.objects.filter(name=user_input)
```

### API Input Validation

Always validate and sanitize input:
```python
# ✅ Use DRF serializers for validation
class BookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = '__all__'
    
    def validate_check_in(self, value):
        if value < timezone.now().date():
            raise serializers.ValidationError("Check-in date cannot be in the past")
        return value
```

### Password Handling

Never log or expose passwords:
```python
# ❌ BAD
logger.info(f"User logged in with password: {password}")

# ✅ GOOD
logger.info(f"User {username} logged in successfully")
```

### File Uploads

Validate file types and sizes:
```python
# ✅ GOOD
ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.pdf'}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

def validate_file(file):
    ext = os.path.splitext(file.name)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValidationError("Invalid file type")
    if file.size > MAX_FILE_SIZE:
        raise ValidationError("File too large")
```

## Dependency Management

- Review Dependabot PRs promptly
- Test dependency updates in staging before production
- Pin critical dependencies to specific versions
- Run `safety check` before releasing

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find similar problems
3. Prepare fixes for all supported versions
4. Release patched versions as soon as possible

## Security Updates

Security updates will be released as:
- **Critical**: Within 24-48 hours
- **High**: Within 1 week
- **Medium**: Within 1 month
- **Low**: Next regular release

## Acknowledgments

We appreciate the security research community's efforts in responsibly disclosing vulnerabilities. Contributors who report valid security issues will be acknowledged in our security advisories (unless they prefer to remain anonymous).

## Contact

- **Security Issues**: [your-email@domain.com]
- **General Issues**: Use GitHub Issues
- **Private Concerns**: [your-email@domain.com]

---

**Last Updated**: January 20, 2026
