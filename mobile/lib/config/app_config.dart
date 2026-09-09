import 'environment.dart';

class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUrl});

  final AppEnvironment environment;
  final String apiBaseUrl;

  bool get isDevelopment => environment == AppEnvironment.development;

  bool get isProduction => environment == AppEnvironment.production;
}
