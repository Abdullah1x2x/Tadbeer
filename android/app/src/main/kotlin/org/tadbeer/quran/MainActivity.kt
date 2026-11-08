package org.tadbeer.quran

import android.content.Intent
import android.hardware.GeomagneticField
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
                    // The compass reads magnetic north; the Qibla bearing is from
                    // true north. The gap here, in degrees east.
                    "declination" -> {
                        val lat = call.argument<Double>("latitude") ?: 0.0
                        val lon = call.argument<Double>("longitude") ?: 0.0
                        val field = GeomagneticField(
                            lat.toFloat(), lon.toFloat(), 0f, System.currentTimeMillis(),
                        )
                        result.success(field.declination.toDouble())
                    }
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
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            try {
                                val file = java.io.File(filePath)
                                if (file.exists()) {
                                    val uri = androidx.core.content.FileProvider.getUriForFile(
                                        this,
                                        "$packageName.fileprovider",
                                        file
                                    )
                                    val intent = Intent(Intent.ACTION_VIEW).apply {
                                        setDataAndType(uri, "application/vnd.android.package-archive")
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    startActivity(intent)
                                    result.success(true)
                                } else {
                                    result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                                }
                            } catch (e: Exception) {
                                result.error("INSTALL_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "filePath is null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
