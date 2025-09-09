import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'otp_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _nameController = TextEditingController();
  final _raController = TextEditingController();
  final _phoneController = TextEditingController();

  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _imageBytes;
  String? _imagePath;
  String? _imageName;
  bool _sending = false;

  // --- helpers ---
  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS: return 'ios';
      default: return 'other';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 92);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _picked = file;
      _imageBytes = bytes;
      _imagePath = file.path;
      _imageName = file.name.isNotEmpty ? file.name : 'foto.jpg';
    });
  }

  Future<bool> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _raController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _imageBytes == null ||
        _imageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos e selecione uma foto')),
      );
      return false;
    }

    setState(() => _sending = true);
    try {
      // 👉 Ajuste seu host aqui:
      final base = 'http://10.0.0.113:5001';
      final usersUri   = Uri.parse('$base/api/users');
      final deviceUri  = Uri.parse('$base/api/devices/register');

      // 1) Cadastro do usuário (multipart com a foto)
      final req = http.MultipartRequest('POST', usersUri)
        ..fields['username'] = _nameController.text.trim()
        ..fields['email']    = _raController.text.trim()   // ajuste se "RA" não for email
        ..fields['phone']    = _phoneController.text.trim();

      final mime = lookupMimeType(_imageName!, headerBytes: _imageBytes!) ?? 'image/jpeg';
      final mediaType = MediaType.parse(mime);

      // Envia APENAS um campo de arquivo (o nome deve bater com o backend)
      req.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        _imageBytes!,
        filename: _imageName!,
        contentType: mediaType,
      ));

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no cadastro: ${resp.statusCode}')),
      );
      return false;
}


      // 2) Pega o user_id retornado
      final decoded = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      // tente acomodar ambos formatos: {"user": { "id": ... }} OU {"id": ...}
      final user = (decoded is Map && decoded['user'] is Map) ? decoded['user'] : decoded;
      final userId = (user is Map) ? (user['id'] ?? user['user_id']) : null;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível obter o ID do usuário após cadastro')),
        );
        return false;
      }

      // 3) Busca o FCM token e envia para /api/devices/register
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        final reg = await http.post(
          deviceUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'fcm_token': token,
            'platform': _platformLabel(),
          }),
        );
        debugPrint('Device register: ${reg.statusCode} - ${reg.body}');
      } else {
        debugPrint('FCM token indisponível no momento');
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar: $e')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onRegister() async {
    final ok = await _submit();
    if (!ok || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          verificationId: 'test_verification_id',
          name: _nameController.text,
          ra: _raController.text,
          phone: _phoneController.text,
          imagePath: _imagePath ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: AbsorbPointer(
        absorbing: _sending,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: _raController, decoration: const InputDecoration(labelText: 'RA')),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(onPressed: () => _pickImage(ImageSource.camera), child: const Text('Tirar Foto')),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: () => _pickImage(ImageSource.gallery), child: const Text('Galeria')),
                ],
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 10),
                Image.memory(_imageBytes!, height: 150, width: 150, fit: BoxFit.cover),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _onRegister,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_sending ? 'Enviando...' : 'Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
