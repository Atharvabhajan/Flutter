package com.example.silent_emergency_shield

import android.view.KeyEvent
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ses.volume_button"
    private var eventSink: EventChannel.EventSink? = null
    private var serviceStarted = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up EventChannel for volume button events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    VolumeListenerService.eventSink = events
                    // Don't start service here — wait until first volume press
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    VolumeListenerService.eventSink = null
                }
            }
        )
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            // Start foreground service on first volume press (only once)
            if (!serviceStarted) {
                startVolumeListenerService()
                serviceStarted = true
            }
            eventSink?.success("volume_pressed")
            return true  // Swallow the event to prevent system volume UI from showing
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun startVolumeListenerService() {
        val serviceIntent = Intent(this, VolumeListenerService::class.java)
        startForegroundService(serviceIntent)
    }
}

