import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../providers/inbox_provider.dart';
import 'chat_thread_screen.dart';
import 'package:intl/intl.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return OnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes mensajes todavía.',
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: provider.loadChats,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: provider.chats.length,
                  itemBuilder: (context, index) {
                    final chat = provider.chats[index];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                colorScheme.primary.withValues(alpha: 0.1),
                                colorScheme.surface.withValues(alpha: 0.85),
                              ),
                              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: colorScheme.primary.withOpacity(0.15),
                                backgroundImage: chat.otherParticipantAvatarUrl != null && chat.otherParticipantAvatarUrl!.isNotEmpty 
                                    ? NetworkImage(chat.otherParticipantAvatarUrl!) 
                                    : null,
                                child: (chat.otherParticipantAvatarUrl == null || chat.otherParticipantAvatarUrl!.isEmpty)
                                    ? Text(
                                        chat.otherParticipantName.isNotEmpty ? chat.otherParticipantName[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                chat.otherParticipantName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  chat.receptionTitle,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDate(chat.lastMessageAt),
                                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  if (chat.unreadCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary.withOpacity(0.4),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        chat.unreadCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
    );
  }
}
