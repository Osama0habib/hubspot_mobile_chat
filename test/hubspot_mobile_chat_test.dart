import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:hubspot_mobile_chat/hubspot_mobile_chat.dart';
import 'package:hubspot_mobile_chat/src/messages.g.dart';
import 'package:hubspot_mobile_chat/src/models.dart'
    show kHubspotConfigErrorCode;

/// Records calls so we can assert arg/enum marshalling (Constitution V).
class _FakeHostApi extends HubspotHostApi {
  final List<String> calls = [];
  Map<String, String>? lastProperties;
  String? lastEmail;
  String? lastToken;
  String? lastChatFlow;
  PushData? lastPushData;
  String? lastPushToken;
  Object? throwOnConfigure;

  @override
  Future<void> configure() async {
    calls.add('configure');
    if (throwOnConfigure != null) throw throwOnConfigure!;
  }

  @override
  Future<void> setUserIdentity(String email, String identityToken) async {
    calls.add('setUserIdentity');
    lastEmail = email;
    lastToken = identityToken;
  }

  @override
  Future<void> setChatProperties(Map<String, String> properties) async {
    calls.add('setChatProperties');
    lastProperties = properties;
  }

  @override
  Future<void> openChat(String? chatFlow, PushData? pushData) async {
    calls.add('openChat');
    lastChatFlow = chatFlow;
    lastPushData = pushData;
  }

  @override
  Future<void> registerPushToken(String token) async {
    calls.add('registerPushToken');
    lastPushToken = token;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHostApi fake;
  late HubspotMobileChat plugin;

  setUp(() {
    fake = _FakeHostApi();
    HubspotMobileChat.setInstanceForTesting(fake);
    HubspotMobileChat.debugSupportedPlatformOverride = true;
    plugin = HubspotMobileChat.instance;
  });

  tearDown(() {
    HubspotMobileChat.debugSupportedPlatformOverride = null;
  });

  // US1
  test('configure forwards to host (T013)', () async {
    await plugin.configure();
    expect(fake.calls, contains('configure'));
  });

  test('openChat passes chatFlow and pushData (T013)', () async {
    final pd = PushData(threadId: 't1');
    await plugin.openChat(chatFlow: 'support', pushData: pd);
    expect(fake.lastChatFlow, 'support');
    expect(fake.lastPushData?.threadId, 't1');
  });

  test(
    'configure maps native config error to HubspotConfigError (FR-013)',
    () async {
      fake.throwOnConfigure = PlatformException(
        code: kHubspotConfigErrorCode,
        message: 'bad config',
      );
      expect(plugin.configure(), throwsA(isA<HubspotConfigError>()));
    },
  );

  test('unsupported platform throws UnsupportedError (FR-012)', () async {
    HubspotMobileChat.debugSupportedPlatformOverride = false;
    expect(plugin.configure(), throwsA(isA<UnsupportedError>()));
  });

  // US2
  test('setUserIdentity forwards email and token (T018)', () async {
    await plugin.setUserIdentity(email: 'a@b.com', identityToken: 'tok');
    expect(fake.lastEmail, 'a@b.com');
    expect(fake.lastToken, 'tok');
  });

  test('logout forwards to host (T018)', () async {
    await plugin.logout();
    expect(fake.calls, contains('logout'));
  });

  // US3
  test('registerPushToken forwards token (T023)', () async {
    await plugin.registerPushToken('fcm-123');
    expect(fake.lastPushToken, 'fcm-123');
  });

  // US4
  test(
    'setChatProperties maps ChatPropertyKey to SDK string keys (T028)',
    () async {
      await plugin.setChatProperties({
        ChatPropertyKey.cameraPermissions: 'granted',
        ChatPropertyKey.locationPermissions: 'denied',
      });
      expect(fake.lastProperties, {
        'cameraPermissions': 'granted',
        'locationPermissions': 'denied',
      });
    },
  );
}
