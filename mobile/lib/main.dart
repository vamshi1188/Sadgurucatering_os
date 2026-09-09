import 'package:flutter/material.dart';

import 'app/sadguru_app.dart';
import 'config/app_config.dart';
import 'config/environment.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://localhost:3000/api/v1',
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