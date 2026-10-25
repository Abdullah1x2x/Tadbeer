package com.tadbeer.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // When the app was killed in the background, a tap on the home-screen
    // widget arrives here before Flutter listens for it. Keeping it as the
    // activity's intent lets the app read it once it is ready.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
