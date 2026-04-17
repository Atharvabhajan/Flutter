package com.example.silent_emergency_shield

import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.content.Intent
import android.content.Context
import android.database.ContentObserver
import android.media.AudioManager
import android.net.Uri
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import android.content.pm.ServiceInfo
import io.flutter.plugin.common.EventChannel

/**
 * Foreground service that detects volume button presses while the app is backgrounded.
 * Uses a ContentObserver on the music stream volume URI — fires once per volume change.
 * The triple-press counting logic stays in Dart (EmergencyManager.simulateVolumePress).
 *
 * In the foreground, MainActivity.onKeyDown intercepts and swallows volume events,
 * so the ContentObserver never fires. In the background, the OS adjusts the volume
 * and the ContentObserver fires — one event per press. Both paths emit "volume_pressed"
 * on the same EventChannel, so EmergencyManager handles them identically.
 */
class VolumeListenerService : Service() {
    companion object {
        private const val TAG = "VolumeListenerService"
        private const val CHANNEL_ID = "volume_listener_channel"
        private const val NOTIFICATION_ID = 1337
        var eventSink: EventChannel.EventSink? = null
    }

    private var contentObserver: ContentObserver? = null
    private var audioManager: AudioManager? = null
    private var lastVolume: Int = -1

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "VolumeListenerService created")
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        lastVolume = audioManager!!.getStreamVolume(AudioManager.STREAM_MUSIC)
        createNotificationChannel()

        // Calling startForeground in onCreate is CRITICAL for Android 12+ to avoid SIG 9 crash
        // Using ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE for Emergency Monitoring
        startForeground(
            NOTIFICATION_ID, 
            createNotification(),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "VolumeListenerService started")
        registerVolumeObserver()
        return START_STICKY
    }

    private fun registerVolumeObserver() {
        val volumeUri: Uri = Settings.System.getUriFor("volume_music")
        contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                val currentVolume = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: return
                if (currentVolume != lastVolume) {
                    lastVolume = currentVolume
                    Log.d(TAG, "Background volume press detected")
                    // Each change = one press. Dart-side EmergencyManager counts to 3.
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success("volume_pressed")
                    }
                }
            }
        }
        contentResolver.registerContentObserver(volumeUri, false, contentObserver!!)
        Log.d(TAG, "Volume observer registered")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        contentObserver?.let { contentResolver.unregisterContentObserver(it) }
        contentObserver = null
        Log.d(TAG, "VolumeListenerService destroyed")
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Emergency Alert Service",
            NotificationManager.IMPORTANCE_MIN
        )
        channel.description = "Listening for emergency alerts"
        channel.setShowBadge(false)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Android System")
            .setContentText("Battery synchronization active")
            .setSmallIcon(android.R.drawable.sym_def_app_icon)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setAutoCancel(false)
            .setOngoing(true)
            .build()
    }
}
