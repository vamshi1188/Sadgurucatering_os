// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sadguru Catering OS';

  @override
  String get welcome => 'Welcome';

  @override
  String get home => 'Home';

  @override
  String get english => 'English';

  @override
  String get telugu => 'Telugu';

  @override
  String get language => 'Language';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get noData => 'No data available';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get events => 'Events';

  @override
  String get finance => 'Finance';

  @override
  String get settings => 'Settings';

  @override
  String get networkError =>
      'We couldn\'t connect to the server. Check your connection and try again.';

  @override
  String get timeoutError => 'The request took too long. Please try again.';

  @override
  String get unauthorizedError =>
      'Your session has expired. Please sign in again.';

  @override
  String get forbiddenError =>
      'You don\'t have permission to perform this action.';

  @override
  String get notFoundError => 'The requested resource was not found.';

  @override
  String get validationError => 'Please check your input and try again.';

  @override
  String get serverError =>
      'The server is temporarily unavailable. Please try again.';

  @override
  String get unknownError => 'Something went wrong. Please try again.';
}
