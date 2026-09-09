import 'package:flutter_test/flutter_test.dart';

import 'package:sadguru_catering/config/app_config.dart';
import 'package:sadguru_catering/config/environment.dart';

void main() {
  test('development configuration is identified correctly', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://127.0.0.1:3000/api/v1',
    );

    expect(config.isDevelopment, isTrue);
    expect(config.isProduction, isFalse);
    expect(config.apiBaseUrl, 'http://127.0.0.1:3000/api/v1');
  });

  test('production configuration is identified correctly', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: 'http://13.60.199.18:3000/api/v1',
    );

    expect(config.isDevelopment, isFalse);
    expect(config.isProduction, isTrue);
    expect(
      config.apiBaseUrl,
      'http://13.60.199.18:3000/api/v1',
    );
  });
}
