// Pigeon contract — SOURCE OF TRUTH for the platform-channel API.
// Generated files MUST NOT be hand-edited (Constitution Principle I).
// Regenerate: dart run pigeon --input pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/debuggersight/hubspot_mobile_chat/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.debuggersight.hubspot_mobile_chat',
    ),
    swiftOut:
        'ios/hubspot_mobile_chat/Sources/hubspot_mobile_chat/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'hubspot_mobile_chat',
  ),
)
/// Permission-state keys defined by the HubSpot SDKs. The Dart facade maps each
/// value to the SDK's string key.
enum ChatPropertyKey {
  cameraPermissions,
  photoPermissions,
  notificationPermissions,
  locationPermissions,
}

/// Incoming chat push payload. native -> Dart on receipt; Dart -> native into
/// [HubspotHostApi.openChat] when a notification is tapped.
class PushData {
  PushData({this.messageId, this.threadId, this.raw});

  String? messageId;
  String? threadId;
  Map<String?, String?>? raw;
}

/// Dart -> native. Implemented by the Kotlin/Swift plugin classes, which forward
/// to the native HubspotManager. Holds zero logic on the Dart side.
@HostApi()
abstract class HubspotHostApi {
  /// Initialize the SDK from the bundled config file. Throws on missing/invalid config.
  @async
  void configure();

  /// Associate the chat session with a HubSpot contact. Pass-through token.
  @async
  void setUserIdentity(String email, String identityToken);

  /// Set custom chat properties for the current app session.
  @async
  void setChatProperties(Map<String, String> properties);

  /// Present the HubSpot chat UI. Optional [chatFlow] targets a flow; optional
  /// [pushData] opens the conversation referenced by a tapped notification.
  @async
  void openChat(String? chatFlow, PushData? pushData);

  /// Forward an app-obtained FCM/APNs token to the SDK.
  @async
  void registerPushToken(String token);

  /// Clear stored identity and properties for future sessions.
  @async
  void logout();
}

/// native -> Dart. The plugin invokes this; the Dart facade republishes it as a
/// `Stream<PushData>`.
@FlutterApi()
abstract class HubspotFlutterApi {
  void onNewMessagePush(PushData data);
}
