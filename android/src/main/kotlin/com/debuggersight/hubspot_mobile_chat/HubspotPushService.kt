package com.debuggersight.hubspot_mobile_chat

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.hubspot.mobilesdk.HubspotManager
import com.hubspot.mobilesdk.firebase.PushNotificationChatData
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Forwards FCM messages to the HubSpot SDK and surfaces HubSpot chat pushes to
 * Dart via [HubspotFlutterApi.onNewMessagePush] (FR-007). The app owns FCM
 * registration; this only forwards. Register it in the app manifest, or call
 * through from the app's own FirebaseMessagingService.
 */
class HubspotPushService : FirebaseMessagingService() {

    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        scope.launch {
            runCatching { HubspotManager.getInstance(applicationContext).setPushToken(token) }
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        val data = message.data
        // Only act on HubSpot chat pushes; let the app handle the rest.
        if (!HubspotManager.isHubspotNotification(data)) return

        val chatData = PushNotificationChatData(data)
        val pushData = PushData(
            messageId = data["messageId"],
            threadId = chatData.threadId,
            raw = data.mapKeys { it.key as String? }.mapValues { it.value as String? },
        )
        HubspotMobileChatPlugin.pushDelegate?.onNewMessagePush(pushData) {}
    }
}
