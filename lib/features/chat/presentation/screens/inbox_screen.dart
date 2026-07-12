import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../providers/inbox_provider.dart';
import 'chat_thread_screen.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  static Widget route() {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = InboxProvider(ChatRepositoryImpl());
        Future.microtask(() => provider.loadChats());
        return provider;
      },
      child: const InboxScreen(),
    );
  }

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: Consumer<InboxProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadChats(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.chats.isEmpty) {
            return const Center(
              child: Text(
                'No tienes mensajes todavía.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadChats,
            child: ListView.builder(
              itemCount: provider.chats.length,
              itemBuilder: (context, index) {
                final chat = provider.chats[index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      chat.otherParticipantName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(chat.receptionTitle),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(chat.lastMessageAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (chat.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatThreadScreen.route(
                            chatId: chat.id,
                            otherParticipantName: chat.otherParticipantName,
                          ),
                        ),
                      );
                      // Recargar al volver para actualizar leídos o nuevos mensajes
                      provider.loadChats();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
