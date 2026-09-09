import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/config/environment.dart';

void main() {
  test('development configuration is identified correctly', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://localhost:3000/api/v1',
    );

    expect(config.isDevelopment, isTrue);
    expect(config.isProduction, isFalse);
    expect(config.apiBaseUrl, 'http://localhost:3000/api/v1');
  });

  test('production configuration is identified correctly', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://api.example.com/api/v1',
    );

    expect(config.isDevelopment, isFalse);
    expect(config.isProduction, isTrue);
  });
}
