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
import 'home_screen.dart';
import '../../services/session.dart';

class PhoneInputScreen extends StatefulWidget {
  final SessionService session;
  const PhoneInputScreen({super.key, required this.session});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  // backend base
  final String base = 'http://10.0.0.113:5001';

  // cadastro
  final _nameController = TextEditingController();
  final _raController = TextEditingController();
  final _phoneController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  final _picker = ImagePicker();

  // login
  final _loginIdController = TextEditingController();

  bool _sending = false;

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
      _imageBytes = bytes;
      _imageName  = file.name.isNotEmpty ? file.name : 'foto.jpg';
    });
  }

  // -------- CADASTRO --------
  Future<bool> _submitRegister() async {
    print(widget.session.currentUserId());
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
      final usersUri  = Uri.parse('$base/api/users');
      final deviceUri = Uri.parse('$base/api/devices/register');

      final req = http.MultipartRequest('POST', usersUri)
        ..fields['username'] = _nameController.text.trim()
        ..fields['email']    = _raController.text.trim()  // RA no campo email (como seu backend)
        ..fields['phone']    = _phoneController.text.trim();

      final mime = lookupMimeType(_imageName!, headerBytes: _imageBytes!) ?? 'image/jpeg';
      final mediaType = MediaType.parse(mime);

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

      // user_id
      final decoded = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      final user    = (decoded is Map && decoded['user'] is Map) ? decoded['user'] : decoded;
      final userId  = (user is Map) ? (user['id'] ?? user['user_id']) : null;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível obter o ID do usuário após cadastro')),
        );
        return false;
      }

      // 1) salve o user_id imediatamente
      await widget.session.saveSession(userId: userId);

      // 2) tente pegar o token e registrar o device (melhoria posterior, não bloqueia login)
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          deviceUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'fcm_token': token,
            'platform': _platformLabel(),
          }),
        );
        // atualize o token localmente (opcional)
        await widget.session.saveSession(userId: userId, fcmToken: token);
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

  // -------- LOGIN --------
  Future<bool> _submitLogin() async {
    if (_loginIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu RA, email ou username')),
      );
      return false;
    }

    setState(() => _sending = true);
    try {
      // usa seu endpoint de busca
      final searchUri = Uri.parse(
        '$base/api/users/search?q=${Uri.encodeQueryComponent(_loginIdController.text.trim())}',
      );
      final res = await http.get(searchUri);
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao buscar usuário: ${res.statusCode}')),
        );
        return false;
      }

      final data  = jsonDecode(res.body) as Map<String, dynamic>;
      final user = data['user'];
      //final users = (data['user'] as List?) ?? [];
      //if (users.isEmpty) {
      //  ScaffoldMessenger.of(context).showSnackBar(
      //    const SnackBar(content: Text('Usuário não encontrado')),
      //  );
      //  return false;
      //}
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não encontrado')),
        );
        return false;
      }
      final userId = user['id'] as int?;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resposta inválida do servidor')),
        );
        return false;
      }

      // 1) salve o user_id imediatamente
      await widget.session.saveSession(userId: userId);

      // 2) depois tente registrar o token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('$base/api/devices/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'fcm_token': token,
            'platform': _platformLabel(),
          }),
        );
        await widget.session.saveSession(userId: userId, fcmToken: token);
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login: $e')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ação do botão principal (depende da aba)
  Future<void> _onPrimaryAction(int tabIndex) async {
    final ok = tabIndex == 0 ? await _submitRegister() : await _submitLogin();
    if (!ok || !mounted) return;

    if (tabIndex == 0) {
      // após cadastro -> OTP (ou vá direto pra Home se preferir)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            verificationId: 'test_verification_id',
            name: _nameController.text,
            ra: _raController.text,
            phone: _phoneController.text,
            imagePath: '', // opcional
            session: widget.session,
          ),
        ),
      );
    } else {
      // login -> Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(session: widget.session, onLogout: () => widget.session.logout())),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (ctx) {
          final tabIndex = DefaultTabController.of(ctx).index;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Acesso'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Cadastrar'),
                  Tab(text: 'Entrar'),
                ],
              ),
            ),
            body: AbsorbPointer(
              absorbing: _sending,
              child: TabBarView(
                children: [
                  // ----------- Aba CADASTRAR -----------
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome')),
                        TextField(controller: _raController, decoration: const InputDecoration(labelText: 'RA (ou e-mail)')),
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
                            onPressed: _sending ? null : () => _onPrimaryAction(0),
                            icon: _sending
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check),
                            label: Text(_sending ? 'Enviando...' : 'Cadastrar'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ----------- Aba ENTRAR -----------
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _loginIdController,
                          decoration: const InputDecoration(
                            labelText: 'RA / e-mail / username',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sending ? null : () => _onPrimaryAction(1),
                            icon: _sending
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.login),
                            label: Text(_sending ? 'Enviando...' : 'Entrar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
