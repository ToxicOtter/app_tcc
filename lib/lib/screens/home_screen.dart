import 'package:flutter/material.dart';
import 'package:teste/lib/screens/phone_input_screen.dart';

class HomeScreen extends StatelessWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Push Notifications'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bem-vindo, $name'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneInputScreen(),
                    ),
                  );
                },
                child: const Text('Ir para outra tela'),
              ),
            ],
          ),
        ),
      );
}