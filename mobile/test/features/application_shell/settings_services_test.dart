import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/features/application_shell/services/settings_services.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('sadguru-settings-');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('shares installed APK file when available', () async {
    final apk = File('${tempDirectory.path}/installed.apk');
    await apk.writeAsBytes([0x50, 0x4b, 0x03, 0x04]);
    final launcher = _RecordingShareLauncher();
    final service = AppSharingService(
      apkProvider: _FakeInstalledApkProvider(apk.path),
      shareLauncher: launcher,
      distributionUrl: 'https://downloads.example.com/app.apk',
    );

    await service.shareApp();

    expect(launcher.sharedApkPath, apk.path);
    expect(launcher.sharedUrl, isNull);
  });

  test(
    'uses configured HTTPS APK URL if installed package unavailable',
    () async {
      final launcher = _RecordingShareLauncher();
      final service = AppSharingService(
        apkProvider: const _FakeInstalledApkProvider(null),
        shareLauncher: launcher,
        distributionUrl: 'https://downloads.example.com/sadguru.apk',
      );

      await service.shareApp();

      expect(
        launcher.sharedUrl,
        Uri.parse('https://downloads.example.com/sadguru.apk'),
      );
      expect(launcher.sharedApkPath, isNull);
    },
  );

  test(
    'does not silently share text when no APK or valid URL is available',
    () {
      final launcher = _RecordingShareLauncher();
      final service = AppSharingService(
        apkProvider: const _FakeInstalledApkProvider(null),
        shareLauncher: launcher,
      );

      expect(service.shareApp(), throwsA(isA<ShareAppUnavailableException>()));
      expect(launcher.sharedUrl, isNull);
    },
  );

  test('rejects non-HTTPS distribution URL', () {
    final service = AppSharingService(
      apkProvider: const _FakeInstalledApkProvider(null),
      shareLauncher: _RecordingShareLauncher(),
      distributionUrl: 'http://example.com/app.apk',
    );

    expect(service.shareApp(), throwsA(isA<ShareAppUnavailableException>()));
  });
}

class _FakeInstalledApkProvider implements InstalledApkProvider {
  const _FakeInstalledApkProvider(this.path);

  final String? path;

  @override
  Future<String?> prepareInstalledApk() async => path;
}

class _RecordingShareLauncher implements NativeShareLauncher {
  String? sharedApkPath;
  Uri? sharedUrl;

  @override
  Future<void> shareApk(String path) async {
    sharedApkPath = path;
  }

  @override
  Future<void> shareDistributionUrl(Uri url) async {
    sharedUrl = url;
  }
}
