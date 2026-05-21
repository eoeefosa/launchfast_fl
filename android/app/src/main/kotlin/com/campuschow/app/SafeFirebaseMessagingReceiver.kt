package com.campuschow.app

import android.content.Context
import android.content.Intent
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver
import java.util.concurrent.Executors

class SafeFirebaseMessagingReceiver : FlutterFirebaseMessagingReceiver() {
    private val executor = Executors.newCachedThreadPool()

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        executor.execute {
            try {
                super.onReceive(context, intent)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                try {
                    pendingResult.finish()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
}
