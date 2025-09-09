import 'package:flutter/material.dart';
import 'screens/phone_input_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro por SMS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PhoneInputScreen(),
    );
  }
}
