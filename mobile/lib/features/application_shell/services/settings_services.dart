import 'dart:io';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class AppVersionInfo {
  const AppVersionInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;
}

abstract interface class AppInfoProvider {
  Future<AppVersionInfo> getAppInfo();
}

class PackageAppInfoProvider implements AppInfoProvider {
  const PackageAppInfoProvider();

  @override
  Future<AppVersionInfo> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}

abstract interface class InstalledApkProvider {
  Future<String?> prepareInstalledApk();
}

class AndroidInstalledApkProvider implements InstalledApkProvider {
  const AndroidInstalledApkProvider();

  static const MethodChannel _channel = MethodChannel(
    'com.sadgurucatering.sadguru_catering/app_info',
  );

  @override
  Future<String?> prepareInstalledApk() {
    return _channel.invokeMethod<String>('prepareApkForSharing');
  }
}

abstract interface class NativeShareLauncher {
  Future<void> shareApk(String path);
  Future<void> shareDistributionUrl(Uri url);
}

class SharePlusLauncher implements NativeShareLauncher {
  const SharePlusLauncher();

  @override
  Future<void> shareApk(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Sadguru Catering OS',
        files: [
          XFile(
            path,
            mimeType: 'application/vnd.android.package-archive',
            name: 'sadguru-catering-os.apk',
          ),
        ],
      ),
    );
  }

  @override
  Future<void> shareDistributionUrl(Uri url) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Sadguru Catering OS',
        text: 'Install Sadguru Catering OS: $url',
      ),
    );
  }
}

class ShareAppUnavailableException implements Exception {
  const ShareAppUnavailableException();
}

class AppSharingService {
  AppSharingService({
    InstalledApkProvider? apkProvider,
    NativeShareLauncher? shareLauncher,
    this.distributionUrl = const String.fromEnvironment('APP_DISTRIBUTION_URL'),
  }) : _apkProvider = apkProvider ?? const AndroidInstalledApkProvider(),
       _shareLauncher = shareLauncher ?? const SharePlusLauncher();

  final InstalledApkProvider _apkProvider;
  final NativeShareLauncher _shareLauncher;
  final String distributionUrl;

  Future<void> shareApp() async {
    String? apkPath;
    try {
      apkPath = await _apkProvider.prepareInstalledApk();
    } on PlatformException {
      apkPath = null;
    } on MissingPluginException {
      apkPath = null;
    }

    if (apkPath != null) {
      final apkFile = File(apkPath);
      if (await apkFile.exists() && await apkFile.length() > 0) {
        await _shareLauncher.shareApk(apkPath);
        return;
      }
    }

    final distributionUri = Uri.tryParse(distributionUrl.trim());
    if (distributionUri != null &&
        distributionUri.scheme == 'https' &&
        distributionUri.host.isNotEmpty) {
      await _shareLauncher.shareDistributionUrl(distributionUri);
      return;
    }

    throw const ShareAppUnavailableException();
  }
}
