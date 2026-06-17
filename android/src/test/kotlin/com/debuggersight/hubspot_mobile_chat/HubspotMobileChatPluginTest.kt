package com.debuggersight.hubspot_mobile_chat

import kotlin.test.Test
import kotlin.test.assertNotNull

/*
 * Minimal unit test of the Kotlin portion of this plugin. Behavioral coverage of the
 * platform-channel API lives in the Dart tests (test/hubspot_mobile_chat_test.dart),
 * which exercise the facade against a mock host API. Full native behavior is validated
 * end-to-end via the example app.
 */
internal class HubspotMobileChatPluginTest {
    @Test
    fun plugin_canBeInstantiated() {
        assertNotNull(HubspotMobileChatPlugin())
    }
}
