import 'package:flutter_test/flutter_test.dart';
import 'package:hubspot_mobile_chat_example/main.dart';

void main() {
  testWidgets('example app builds and shows controls', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Open Chat'), findsOneWidget);
    expect(find.text('Set Identity'), findsOneWidget);
  });
}
