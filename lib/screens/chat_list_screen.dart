import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lad_admin/providers/chat_provider.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(chatSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Cream
      appBar: AppBar(
        title: const Text('Сообщения', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: sessionsState.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Нет активных чатов', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _ChatSessionTile(session: session);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2D4A3E))),
        error: (err, stack) => Center(child: Text('Ошибка загрузки: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(chatSessionsProvider.notifier).fetchSessions(),
        backgroundColor: const Color(0xFF2D4A3E),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

class _ChatSessionTile extends StatelessWidget {
  final dynamic session;
  const _ChatSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    final dateString = dateFormat.format(session.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFB5CDB2), // Sage Light
          child: Text(
            (session.visitorName?[0] ?? 'A').toUpperCase(),
            style: const TextStyle(color: Color(0xFF2D4A3E), fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.visitorName ?? 'Анонимный посетитель',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              dateString,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            session.lastMessage ?? 'Начать переписку...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        onTap: () => context.go('/chat/${session.id}'),
      ),
    );
  }
}
