import 'package:flutter/material.dart';

import 'app/sadguru_app.dart';
import 'config/app_config.dart';
import 'config/environment.dart';
import 'core/network/api_client.dart';

const _environmentName = String.fromEnvironment(
  'APP_ENV',
  defaultValue: 'production',
);

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://13.60.199.18:3000/api/v1',
);

AppEnvironment _parseEnvironment(String value) {
  switch (value) {
    case 'production':
      return AppEnvironment.production;
    case 'development':
      return AppEnvironment.development;
    default:
      throw StateError('Unsupported APP_ENV: $value');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig(
    environment: _parseEnvironment(_environmentName),
    apiBaseUrl: _apiBaseUrl,
  );

  final apiClient = await ApiClient.create(
    baseUrl: config.apiBaseUrl,
  );

  runApp(
    SadguruApp(
      config: config,
      apiClient: apiClient,
    ),
  );
}
