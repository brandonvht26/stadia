import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../providers/chat_thread_provider.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';
import 'dart:ui';

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
        0.0, // 0.0 is the bottom for a reversed ListView
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
    return OnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.otherParticipantName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? Theme.of(context).colorScheme.primary 
                              : (isDark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerHighest),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              DateFormat('HH:mm').format(message.createdAt.toLocal()),
                              style: TextStyle(
                                color: isMe 
                                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) 
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                        ),
                        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1))),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  ),
                                  onSubmitted: (_) => _sendMessage(provider),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                                  onPressed: () => _sendMessage(provider),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
