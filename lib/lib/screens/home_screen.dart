import 'package:flutter/material.dart';
import 'package:teste/lib/screens/phone_input_screen.dart';
import 'package:teste/lib/screens/notification_history_screen.dart';
import 'package:teste/services/session.dart';

class HomeScreen extends StatelessWidget {
  //final String name;
  //const HomeScreen({super.key, required this.name});

  final Future<bool> Function() onLogout;
  final SessionService session;
  const HomeScreen({super.key, required this.onLogout, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text('Histórico de notificações'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Sair'),
              onPressed: () async {
                await onLogout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => PhoneInputScreen(session: session)),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}