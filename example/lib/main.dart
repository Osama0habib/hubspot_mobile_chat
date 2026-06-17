import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hubspot_mobile_chat/hubspot_mobile_chat.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _hubspot = HubspotMobileChat.instance;
  final _emailCtrl = TextEditingController(text: 'visitor@example.com');
  final _tokenCtrl = TextEditingController();
  final _flowCtrl = TextEditingController(text: 'qanoniah-mobile');
  String _status = 'Not initialized';
  StreamSubscription<PushData>? _pushSub;

  @override
  void initState() {
    super.initState();
    // US3: observe new-message push events.
    _pushSub = _hubspot.onMessagePush.listen((push) {
      debugPrint('[hubspot] ⇣ push thread=${push.threadId} msg=${push.messageId}');
      setState(() => _status = 'Push: thread=${push.threadId}');
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    debugPrint('[hubspot] → $label');
    try {
      await action();
      debugPrint('[hubspot] ✓ $label OK');
      setState(() => _status = '$label OK');
    } on HubspotConfigError catch (e) {
      debugPrint('[hubspot] ✗ $label config error: ${e.message}');
      setState(() => _status = '$label config error: ${e.message}');
    } catch (e) {
      debugPrint('[hubspot] ✗ $label failed: $e');
      setState(() => _status = '$label failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('HubSpot Mobile Chat')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // US1
              ElevatedButton(
                onPressed: () => _run('Initialize', _hubspot.configure),
                child: const Text('Initialize'),
              ),
              TextField(
                controller: _flowCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chat flow (optional)',
                ),
              ),
              ElevatedButton(
                onPressed: () => _run('Open chat', () {
                  final flow = _flowCtrl.text.trim();
                  return _hubspot.openChat(
                    chatFlow: flow.isEmpty ? null : flow,
                  );
                }),
                child: const Text('Open Chat'),
              ),
              const Divider(),
              // US2
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(labelText: 'Identity token'),
              ),
              ElevatedButton(
                onPressed: () => _run('Set identity', () {
                  return _hubspot.setUserIdentity(
                    email: _emailCtrl.text.trim(),
                    identityToken: _tokenCtrl.text.trim(),
                  );
                }),
                child: const Text('Set Identity'),
              ),
              ElevatedButton(
                onPressed: () => _run('Logout', _hubspot.logout),
                child: const Text('Logout'),
              ),
              const Divider(),
              // US4
              ElevatedButton(
                onPressed: () => _run('Set properties', () {
                  return _hubspot.setChatProperties({
                    ChatPropertyKey.cameraPermissions: 'granted',
                    ChatPropertyKey.notificationPermissions: 'granted',
                  });
                }),
                child: const Text('Set Properties'),
              ),
              const Divider(),
              // US3
              ElevatedButton(
                onPressed: () => _run('Register push token', () {
                  // In a real app, supply the FCM/APNs token from your push setup.
                  return _hubspot.registerPushToken('example-device-token');
                }),
                child: const Text('Register Push Token'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
