import '../../localization/app_localizations.dart';
import 'app_error.dart';

String localizedAppErrorMessage(
  AppLocalizations localization,
  AppError error,
) {
  switch (error.type) {
    case AppErrorType.network:
      return localization.networkError;
    case AppErrorType.timeout:
      return localization.timeoutError;
    case AppErrorType.unauthorized:
      return localization.unauthorizedError;
    case AppErrorType.forbidden:
      return localization.forbiddenError;
    case AppErrorType.notFound:
      return localization.notFoundError;
    case AppErrorType.validation:
      return localization.validationError;
    case AppErrorType.server:
      return localization.serverError;
    case AppErrorType.unknown:
      return localization.unknownError;
  }
}