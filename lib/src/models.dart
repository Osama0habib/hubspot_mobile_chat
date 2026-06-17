import 'messages.g.dart' show ChatPropertyKey;

export 'messages.g.dart' show ChatPropertyKey, PushData;

/// Native config-code raised by the host plugins when configuration is missing
/// or invalid, or when chat is opened before [HubspotMobileChat.configure].
/// Part of the uniform error contract (FR-013).
const String kHubspotConfigErrorCode = 'hubspot_config_error';

/// Thrown for missing/invalid HubSpot configuration or open-before-configure.
/// Catchable; never crashes the host app.
class HubspotConfigError implements Exception {
  HubspotConfigError(this.message, {this.details});

  /// Human-readable message forwarded from the native `HubspotConfigError`.
  final String message;
  final Object? details;

  @override
  String toString() => 'HubspotConfigError: $message';
}

/// The SDK string key each [ChatPropertyKey] maps to when sent natively.
extension ChatPropertyKeyMapping on ChatPropertyKey {
  String get sdkKey {
    switch (this) {
      case ChatPropertyKey.cameraPermissions:
        return 'cameraPermissions';
      case ChatPropertyKey.photoPermissions:
        return 'photoPermissions';
      case ChatPropertyKey.notificationPermissions:
        return 'notificationPermissions';
      case ChatPropertyKey.locationPermissions:
        return 'locationPermissions';
    }
  }
}
