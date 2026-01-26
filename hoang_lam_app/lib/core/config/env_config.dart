/// Environment configuration for the app
enum Environment { dev, staging, prod }

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final Duration apiTimeout;
  final Duration tokenRefreshThreshold;

  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.apiTimeout,
    required this.tokenRefreshThreshold,
  });

  /// Development configuration
  static const EnvConfig dev = EnvConfig._(
    environment: Environment.dev,
    apiBaseUrl: 'http://localhost:8000/api/v1',
    appName: 'Hoang Lam Heritage (Dev)',
    enableLogging: true,
    apiTimeout: Duration(seconds: 30),
    tokenRefreshThreshold: Duration(minutes: 5),
  );

  /// Staging configuration
  static const EnvConfig staging = EnvConfig._(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.hoanglam.vn/api/v1',
    appName: 'Hoang Lam Heritage (Staging)',
    enableLogging: true,
    apiTimeout: Duration(seconds: 30),
    tokenRefreshThreshold: Duration(minutes: 5),
  );

  /// Production configuration
  static const EnvConfig prod = EnvConfig._(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.hoanglam.vn/api/v1',
    appName: 'Nhà Nghỉ Hoàng Lâm',
    enableLogging: false,
    apiTimeout: Duration(seconds: 30),
    tokenRefreshThreshold: Duration(minutes: 5),
  );

  /// Current active configuration
  static EnvConfig _current = dev;

  static EnvConfig get current => _current;

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.dev:
        _current = dev;
        break;
      case Environment.staging:
        _current = staging;
        break;
      case Environment.prod:
        _current = prod;
        break;
    }
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}
