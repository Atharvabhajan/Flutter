package com.example.silent_emergency_shield

import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ses.volume_button"
    private var eventSink: EventChannel.EventSink? = null
    private var serviceStarted = false

    // ── Triple-press tracking ─────────────────────────────────────────────────
    // Mirrors the Dart-side constants in VolumeListenerService.dart:
    //   VOLUME_TRIGGER_COUNT = 3, RESET_TIMEOUT = 3 s, DEBOUNCE_THRESHOLD_MS = 400
    private val TRIGGER_COUNT   = 3
    private val RESET_TIMEOUT_MS = 3000L
    private val DEBOUNCE_MS      = 400L

    private var pressCount        = 0
    private var lastPressTime     = 0L
    private val resetHandler      = Handler(Looper.getMainLooper())
    private val resetRunnable     = Runnable { pressCount = 0 }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    VolumeListenerService.eventSink = events
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
            val now = System.currentTimeMillis()

            // ── Debounce: ignore events faster than 400 ms ──────────────────
            if (now - lastPressTime < DEBOUNCE_MS) {
                // Still consume the key so we don't show the volume UI mid-pattern
                return pressCount > 0
            }
            lastPressTime = now

            // ── Start foreground service on very first press ─────────────────
            if (!serviceStarted) {
                startVolumeListenerService()
                serviceStarted = true
            }

            // ── Count the press ──────────────────────────────────────────────
            pressCount++
            resetHandler.removeCallbacks(resetRunnable)

            // Forward to Dart regardless — Dart does the authoritative counting
            eventSink?.success("volume_pressed")

            if (pressCount >= TRIGGER_COUNT) {
                // Pattern complete — reset counter immediately
                pressCount = 0
                // Swallow this final press (no volume UI)
                return true
            }

            // Pattern in progress — schedule a reset and swallow the key
            resetHandler.postDelayed(resetRunnable, RESET_TIMEOUT_MS)
            return true  // Swallow so the volume bar doesn't appear mid-pattern
        }

        // All other keys (and volume presses when count == 0 after reset)
        // fall through naturally. Note: pressCount is always > 0 here only
        // when actively counting, so volume is only blocked during the window.
        return super.onKeyDown(keyCode, event)
    }

    private fun startVolumeListenerService() {
        val serviceIntent = Intent(this, VolumeListenerService::class.java)
        startForegroundService(serviceIntent)
    }
}

