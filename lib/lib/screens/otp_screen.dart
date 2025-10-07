import 'package:flutter/material.dart';
import 'package:teste/services/session.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String name;
  final String ra;
  final String phone;
  final String imagePath;
  final SessionService session;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.name,
    required this.ra,
    required this.phone,
    required this.imagePath,
    required this.session,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _verifyOtp() {
    if (_otpController.text.trim() == "123456") {
      // Ao invés de ir direto para Home, mostramos popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Bem vindo!"),
          content: Text(
            "Bem vindo ${widget.name}. Sua aula será na sala 255 com o prof. Mário hoje. "
            "Você terá aula de x materia. Você tem 50 minutos para chegar na sala, "
            "sua aula começará as 19:10.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // fecha o popup
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(session: widget.session, onLogout: () async {
                      return true;
                    }),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código inválido. Use 123456")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verificação")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: "Código SMS"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text("Verificar"),
            ),
          ],
        ),
      ),
    );
  }
}
