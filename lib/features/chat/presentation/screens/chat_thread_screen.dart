import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../providers/chat_thread_provider.dart';

class ChatThreadScreen extends StatefulWidget {
  final String otherParticipantName;

  const ChatThreadScreen({
    super.key,
    required this.otherParticipantName,
  });

  static Widget route({
    required String chatId,
    required String otherParticipantName,
  }) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = ChatThreadProvider(
          chatRepository: ChatRepositoryImpl(),
          chatId: chatId,
        );
        Future.microtask(() => provider.loadMessages());
        return provider;
      },
      child: ChatThreadScreen(otherParticipantName: otherParticipantName),
    );
  }

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(ChatThreadProvider provider) {
    if (_messageController.text.trim().isEmpty) return;
    
    provider.sendMessage(_messageController.text);
    _messageController.clear();
    
    // Un pequeño delay para permitir que el mensaje se agregue al provider
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherParticipantName),
      ),
      body: Consumer<ChatThreadProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.messages.isEmpty) {
             return Center(child: Text('Error: ${provider.error}'));
          }
          
          // Auto scroll to bottom when new messages arrive if we are already at the bottom
          // A more robust solution uses a reversed ListView, let's implement reversed ListView logic.
          final reversedMessages = provider.messages.reversed.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Importante: invierte el layout para que el final esté abajo
                  controller: _scrollController,
                  itemCount: reversedMessages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemBuilder: (context, index) {
                    final message = reversedMessages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              DateFormat('HH:mm').format(message.createdAt.toLocal()),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          ),
                          onSubmitted: (_) => _sendMessage(provider),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _sendMessage(provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
