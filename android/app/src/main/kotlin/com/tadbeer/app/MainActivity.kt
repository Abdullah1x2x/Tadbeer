package com.tadbeer.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity keeps the recitation playing, with its controls in
// the notification, once the app leaves the screen.
class MainActivity : AudioServiceActivity() {
    // When the app was killed in the background, a tap on the home-screen
    // widget arrives here before Flutter listens for it. Keeping it as the
    // activity's intent lets the app read it once it is ready.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    // The reminders screen reads the maker (for the battery hint) and opens
    // the app's own system settings.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tadbeer/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manufacturer" -> result.success(Build.MANUFACTURER)
                    "openNotificationSettings", "openAppSettings" -> {
                        val notifications = call.method == "openNotificationSettings" &&
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                        val intent = if (notifications) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            )
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
