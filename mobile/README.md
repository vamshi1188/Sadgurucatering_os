# Sadguru Catering OS — Mobile Application

The Android mobile application for Sadguru Catering OS.

This application is part of the main Sadguru Catering OS repository. It is not a separate product or repository.

## Purpose

The mobile application provides the mobile interface for Sadguru Catering OS.

The application will connect to the Sadguru Catering OS Go backend through the versioned API and will provide business workflows for the catering operation.

The initial mobile MVP covers:

- Authentication
- Dashboard
- Events
- Income
- Expenses
- Profitability

The application supports:

- English
- Telugu

## Sharing the Android application

On Android, **Share App** copies the currently installed APK into the app's
cache and shares that APK through the native Android share sheet. If the
installed APK cannot be read, configure an HTTPS download URL for a published
installable APK. Pass it at build time:

```sh
flutter build apk --dart-define=APP_DISTRIBUTION_URL=https://example.com/downloads/sadguru-catering-os.apk
```

The configured URL is used only when sharing the installed APK is unavailable.
Without an installed APK or a valid HTTPS distribution URL, the app displays an
explicit localized error rather than sharing a text-only message.

## Technology

- Flutter
- Dart
- Android
- Material 3
- Flutter localization with ARB files

## Project Structure

```text
mobile/
├── android/                 Android application configuration
├── lib/
│   ├── app/                 Whole application setup
│   ├── config/              Application configuration
│   ├── localization/        English and Telugu translations
│   ├── core/                Shared technical infrastructure
│   └── features/            Business features
├── test/                    Automated tests
├── assets/                  Images, icons, and fonts
├── l10n.yaml                Localization generator configuration
├── pubspec.yaml             Flutter dependencies and project configuration
└── README.md                This document
