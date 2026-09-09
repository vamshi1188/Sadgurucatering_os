import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/errors/app_error.dart';
import 'package:sadguru_catering/core/errors/app_error_localization.dart';
import 'package:sadguru_catering/localization/app_localizations.dart';

void main() {
  test('English error messages are user-friendly and hide backend details', () {
    final message = localizedAppErrorMessage(
      lookupAppLocalizations(const Locale('en')),
      const AppError(
        type: AppErrorType.unauthorized,
        message: 'UNAUTHORIZED: database token abc123',
      ),
    );

    expect(message, 'Your session has expired. Please sign in again.');
    expect(message, isNot(contains('abc123')));
  });

  test('Telugu error messages are localized', () {
    final message = localizedAppErrorMessage(
      lookupAppLocalizations(const Locale('te')),
      const AppError(
        type: AppErrorType.network,
        message: 'Unable to connect to the server',
      ),
    );

    expect(
      message,
      'సర్వర్‌కు కనెక్ట్ కాలేకపోయాం. మీ కనెక్షన్‌ను తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.',
    );
  });
}