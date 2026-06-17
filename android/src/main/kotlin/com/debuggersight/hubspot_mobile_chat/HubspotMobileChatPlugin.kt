package com.debuggersight.hubspot_mobile_chat

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.hubspot.mobilesdk.HubspotManager
import com.hubspot.mobilesdk.HubspotWebActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** Error code shared with the Dart facade for the uniform error contract (FR-013). */
private const val CONFIG_ERROR_CODE = "hubspot_config_error"

/**
 * Android implementation of [HubspotHostApi]. Forwards every call to
 * [HubspotManager] (package `com.hubspot.mobilesdk`, SDK 1.0.8). No business
 * logic beyond marshalling and activity wiring.
 */
class HubspotMobileChatPlugin :
    FlutterPlugin,
    ActivityAware,
    HubspotHostApi {

    private lateinit var context: Context
    private var activity: Activity? = null
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        HubspotHostApi.setUp(binding.binaryMessenger, this)
        pushDelegate = HubspotFlutterApi(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        HubspotHostApi.setUp(binding.binaryMessenger, null)
        pushDelegate = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    private fun manager(): HubspotManager = HubspotManager.getInstance(context)

    override fun configure(callback: (Result<Unit>) -> Unit) {
        // HubspotConfigError is internal to the SDK, so catch broadly and map to the
        // uniform config error code (FR-013).
        try {
            manager().configure()
            callback(Result.success(Unit))
        } catch (e: Throwable) {
            callback(Result.failure(FlutterError(CONFIG_ERROR_CODE, e.message, null)))
        }
    }

    override fun setUserIdentity(
        email: String,
        identityToken: String,
        callback: (Result<Unit>) -> Unit,
    ) {
        manager().setUserIdentity(email, identityToken)
        callback(Result.success(Unit))
    }

    override fun setChatProperties(
        properties: Map<String, String>,
        callback: (Result<Unit>) -> Unit,
    ) {
        manager().setChatProperties(properties)
        callback(Result.success(Unit))
    }

    override fun openChat(
        chatFlow: String?,
        pushData: PushData?,
        callback: (Result<Unit>) -> Unit,
    ) {
        val host = activity
        if (host == null) {
            callback(
                Result.failure(
                    FlutterError(CONFIG_ERROR_CODE, "No Activity to present chat", null),
                ),
            )
            return
        }
        // HubspotWebActivity reads "chatflow" (lowercase) + "hsPushData" extras.
        val intent = Intent(host, HubspotWebActivity::class.java)
        chatFlow?.let { intent.putExtra("chatflow", it) }
        host.startActivity(intent)
        callback(Result.success(Unit))
    }

    override fun registerPushToken(token: String, callback: (Result<Unit>) -> Unit) {
        // setPushToken is a suspend function; run it on a coroutine.
        scope.launch {
            try {
                manager().setPushToken(token)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(FlutterError(CONFIG_ERROR_CODE, e.message, null)))
            }
        }
    }

    override fun logout(callback: (Result<Unit>) -> Unit) {
        // logout is a suspend function.
        scope.launch {
            try {
                manager().logout()
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(FlutterError(CONFIG_ERROR_CODE, e.message, null)))
            }
        }
    }

    companion object {
        /** Set while the engine is attached so the push service can reach Dart. */
        @Volatile
        var pushDelegate: HubspotFlutterApi? = null
    }
}
