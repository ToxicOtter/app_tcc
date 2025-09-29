import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:teste/data/app_notification.dart';
import 'package:teste/data/notification_store.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreen();
}

class _NotificationHistoryScreen extends State<NotificationHistoryScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationStore.getAll();
  }
  
  Future<void> _reload() async {
    final items = await NotificationStore.getAll();
    if (!mounted) return;
    setState(() {
      _future = Future.value(items);
    });
  }

  Future<void> _clear() async {
    await NotificationStore.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de notificações'),
        actions: [
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar Histórico',
          )
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Nenhuma notificação recebida ainda!'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = items[i];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(n.title.isEmpty ? '(Sem título)' : n.title),
                  subtitle: Text(
                    '${n.body}\n${n.timestamp}',
                    maxLines: 3,
                  ),
                  isThreeLine: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Detalhes'),
                        content: SingleChildScrollView(
                          child: Text(const JsonEncoder.withIndent('  ').convert(n.data)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

