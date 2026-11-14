package dev.cloudsync.cloudsync

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Keeps the process (and so the core with its background sync and the
 * write locks of open files) alive while the app is in the background.
 */
class CoreService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Core.start(this)
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL, getString(R.string.sync_channel_name), NotificationManager.IMPORTANCE_MIN).apply {
                description = getString(R.string.sync_channel_description)
            },
        )
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val n = Notification.Builder(this, CHANNEL)
            .setContentTitle("CloudSync")
            .setContentText(getString(R.string.sync_notification_text))
            .setSmallIcon(R.drawable.ic_stat_sync)
            .setContentIntent(open)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(ID, n)
        }
        return START_STICKY
    }

    companion object {
        private const val CHANNEL = "sync"
        private const val ID = 1

        fun start(context: Context) {
            context.startForegroundService(Intent(context, CoreService::class.java))
        }
    }
}
