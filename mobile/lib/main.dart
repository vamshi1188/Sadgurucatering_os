import 'package:flutter/material.dart';

import 'app/sadguru_app.dart';
import 'config/app_config.dart';
import 'config/environment.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://localhost:3000/api/v1',
  );

  runApp(SadguruApp(config: config));
}
