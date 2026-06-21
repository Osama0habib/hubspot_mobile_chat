import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show PlatformException;

import 'src/messages.g.dart';
import 'src/models.dart';

export 'src/models.dart' show ChatPropertyKey, PushData, HubspotConfigError;

/// Thin Dart facade over HubSpot's native Mobile Chat SDKs.
///
/// Holds zero SDK logic (Constitution II): only marshalling, enum mapping, the
/// push stream, and the uniform error contract (FR-013).
class HubspotMobileChat {
  HubspotMobileChat._(this._api);

  static HubspotMobileChat? _instance;

  /// Singleton accessor.
  static HubspotMobileChat get instance =>
      _instance ??= HubspotMobileChat._(HubspotHostApi());

  /// Test seam: inject a mock host API.
  static void setInstanceForTesting(HubspotHostApi api) =>
      _instance = HubspotMobileChat._(api);

  /// Test-only override for the platform-support guard (FR-012/FR-013). When
  /// null (production) support is derived from [Platform].
  static bool? debugSupportedPlatformOverride;

  final HubspotHostApi _api;
  final StreamController<PushData> _pushController =
      StreamController<PushData>.broadcast();
  bool _flutterApiRegistered = false;

  /// Emits a [PushData] for every new-message push surfaced from native (FR-007).
  Stream<PushData> get onMessagePush {
    _ensureFlutterApi();
    return _pushController.stream;
  }

  void _ensureFlutterApi() {
    if (_flutterApiRegistered) return;
    HubspotFlutterApi.setUp(_FlutterApiReceiver(_pushController));
    _flutterApiRegistered = true;
  }

  /// Initialize the SDK from the bundled config file.
  /// Throws [HubspotConfigError] on missing/invalid config (FR-003).
  Future<void> configure() => _guard(() => _api.configure());

  /// Set visitor identity before opening chat. [identityToken] is
  /// server-generated and passed through only (FR-004, FR-011).
  Future<void> setUserIdentity({
    required String email,
    required String identityToken,
  }) => _guard(() => _api.setUserIdentity(email, identityToken));

  /// Set chat properties for the app session. Enum keys are mapped to SDK string
  /// keys here (FR-006).
  Future<void> setChatProperties(Map<ChatPropertyKey, String> properties) {
    final mapped = <String, String>{
      for (final entry in properties.entries) entry.key.sdkKey: entry.value,
    };
    return _guard(() => _api.setChatProperties(mapped));
  }

  /// Set arbitrary string chat properties for the app session. Use this for
  /// keys not covered by [ChatPropertyKey] (e.g. custom locale strings).
  /// Keys are passed to the native SDK as-is — use HubSpot's documented
  /// property key names.
  Future<void> setCustomChatProperties(Map<String, String> properties) =>
      _guard(() => _api.setChatProperties(properties));

  /// Present the HubSpot chat UI (FR-005). [chatFlow] optionally targets a flow;
  /// [pushData] opens the conversation referenced by a tapped notification.
  Future<void> openChat({String? chatFlow, PushData? pushData}) =>
      _guard(() => _api.openChat(chatFlow, pushData));

  /// Forward an app-obtained FCM/APNs push token to the SDK (FR-007).
  Future<void> registerPushToken(String token) {
    _ensureFlutterApi();
    return _guard(() => _api.registerPushToken(token));
  }

  /// Clear stored identity and properties (FR-008).
  Future<void> logout() => _guard(() => _api.logout());

  /// Uniform error contract (FR-013): guards platform support and maps native
  /// failures to typed Dart errors. No method leaks a raw [PlatformException]
  /// for the config case.
  Future<T> _guard<T>(Future<T> Function() body) async {
    if (!_isSupportedPlatform) {
      throw UnsupportedError(
        'hubspot_mobile_chat supports Android and iOS only (FR-012).',
      );
    }
    try {
      return await body();
    } on PlatformException catch (e) {
      if (e.code == kHubspotConfigErrorCode) {
        throw HubspotConfigError(
          e.message ?? 'HubSpot configuration error',
          details: e.details,
        );
      }
      rethrow;
    }
  }

  bool get _isSupportedPlatform =>
      debugSupportedPlatformOverride ?? (Platform.isAndroid || Platform.isIOS);

  /// Release the push stream (typically only in tests).
  Future<void> dispose() => _pushController.close();
}

class _FlutterApiReceiver implements HubspotFlutterApi {
  _FlutterApiReceiver(this._controller);

  final StreamController<PushData> _controller;

  @override
  void onNewMessagePush(PushData data) {
    if (!_controller.isClosed) _controller.add(data);
  }
}
