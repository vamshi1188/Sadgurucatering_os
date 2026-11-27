package com.sadgurucatering.sadguru_catering

import android.content.pm.ApplicationInfo
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.sadgurucatering.sadguru_catering/app_info"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "prepareApkForSharing") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    @Suppress("DEPRECATION")
                    val applicationInfo: ApplicationInfo =
                        packageManager.getApplicationInfo(packageName, 0)
                    val installedApk = File(applicationInfo.sourceDir)
                    if (!installedApk.isFile || installedApk.length() == 0L) {
                        result.success(null)
                        return@setMethodCallHandler
                    }

                    val shareableApk = File(cacheDir, "sadguru-catering-os.apk")
                    FileInputStream(installedApk).use { input ->
                        FileOutputStream(shareableApk).use { output ->
                            input.copyTo(output)
                        }
                    }
                    result.success(shareableApk.absolutePath)
                } catch (exception: Exception) {
                    result.error(
                        "APK_UNAVAILABLE",
                        "Unable to prepare the installed application for sharing.",
                        null,
                    )
                }
            }
    }
}
