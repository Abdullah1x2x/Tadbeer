package com.tadbeer.app

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity

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
}
