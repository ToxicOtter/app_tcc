import 'package:flutter/material.dart';
import 'package:teste/lib/screens/home_screen.dart';
import 'package:teste/lib/screens/notification_screen.dart';
import 'lib/screens/phone_input_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'api/firebase_api.dart';
import 'services/session.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootApp()); // mostra uma tela de loading enquanto inicializa
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});
  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  late final SessionService _session = SessionService('http://10.0.0.113:5001');
  bool? _isLogged;

  @override
  void initState() {
    super.initState();
    _bootstrap(); // não aguarde no main
  }

  // Future<void> _bootstrap() async {
  //   try {
  //     // Firebase só uma vez
  //     if (Firebase.apps.isEmpty) {
  //       await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //     }

  //     // registra handler de background
  //     FirebaseApi.registerBackgroundHandler();

  //     // inicie notificações sem bloquear a UI
  //     // (se preferir aguardar, use um timeout curto)
  //     unawaited(FirebaseApi().initNotifications());

  //     // tente renovar sessão; não deixe travar se o servidor estiver off
  //     await _session.handleTokenRefresh().timeout(const Duration(seconds: 6)).catchError((_) {});
  //     final userId = await _session.currentUserId().timeout(const Duration(seconds: 30)).catchError((_) => null);
  //     print(_isLogged);
  //     if (!mounted) return;
  //     print(_isLogged);
  //     setState(() => _isLogged = userId != null);
  //   } catch (e) {
  //     // se algo falhar, cai para a tela de login
  //     debugPrint('Bootstrap error: $e');
  //     print(_isLogged);
  //     if (!mounted) return;
  //     print(_isLogged);
  //     setState(() => _isLogged = false);
  //   }
  // }

  Future<void> _bootstrap() async {
    // 1) Firebase – se falhar, ainda assim seguimos
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    } catch (e) {
      debugPrint('[Boot] Firebase init falhou: $e');
    }

    // 2) Notificações – não bloqueie o fluxo de login
    try {
      FirebaseApi.registerBackgroundHandler();
      unawaited(FirebaseApi().initNotifications()); // não aguardar
      unawaited(_session.handleTokenRefresh());     // não aguardar
    } catch (e) {
      debugPrint('[Boot] Notificações falharam: $e'); // ok seguir sem isso
    }

    // 3) Decidir tela inicial SOMENTE pelo user_id salvo
    try {
      final userId = await _session.currentUserId();
      debugPrint('[Boot] userId lido no startup = $userId');
      if (!mounted) return;
      setState(() => _isLogged = userId != null);
    } catch (e) {
      debugPrint('[Boot] Erro lendo sessão: $e');
      if (!mounted) return;
      setState(() => _isLogged = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Splash/loading enquanto _isLogged é nulo
    if (_isLogged == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      home: _isLogged!
          ? HomeScreen(session: _session, onLogout: () => _session.logout())
          : PhoneInputScreen(session: _session),
    );
  }
}

// utilitário para "ignorar" o await conscientemente
void unawaited(Future<void> f) {}


//class MyApp extends StatelessWidget {
//  final SessionService session;
//  final bool isLogged;
//  const MyApp({super.key, required this.session, required this.isLogged});

  //@override
  //Widget build(BuildContext context) {
  //  return MaterialApp(
  //    title: 'Cadastro por SMS',
  //    theme: ThemeData(primarySwatch: Colors.blue),
  //    navigatorKey: navigatorKey,
  //    home: const HomeScreen(name:'teste'),
  //    routes: {
  //      NotificationScreen.route: (context) => const NotificationScreen(),
  //    },
  //  );
  //}

//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: isLogged ? HomeScreen(onLogout: () => session.logout())
//                    : const PhoneInputScreen(),
//    );
//  }
//}
