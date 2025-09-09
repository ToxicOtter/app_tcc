import 'package:flutter/material.dart';
import 'package:teste/lib/screens/home_screen.dart';
import 'package:teste/lib/screens/notification_screen.dart';
import 'lib/screens/phone_input_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'api/firebase_api.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro por SMS',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey,
      home: const HomeScreen(name:'teste'),
      routes: {
        NotificationScreen.route: (context) => const NotificationScreen(),
      },
    );
  }
}
