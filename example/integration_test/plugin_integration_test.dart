// Integration test scaffold. Real end-to-end validation (chat round-trip,
// identity attribution, push) requires a configured HubSpot portal and a device
// — see the feature quickstart.md. This smoke test just confirms the plugin
// singleton is reachable.
import 'package:flutter_test/flutter_test.dart';
import 'package:hubspot_mobile_chat/hubspot_mobile_chat.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plugin singleton is available', (tester) async {
    expect(HubspotMobileChat.instance, isNotNull);
  });
}
