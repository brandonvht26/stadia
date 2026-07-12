import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatThreadProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final String chatId;
  
  StreamSubscription<MessageEntity>? _subscription;

  List<MessageEntity> _messages = [];
  List<MessageEntity> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChatThreadProvider({
    required ChatRepository chatRepository,
    required this.chatId,
  }) : _chatRepository = chatRepository {
    _initRealtime();
  }

  void _initRealtime() {
    _subscription = _chatRepository.subscribeToNewMessages(chatId).listen((newMessage) {
      // Evitar duplicados por optimistic append
      // (Comparamos por id local/optimista vs real o contenido cercano)
      // Como un optimistic id suele ser 'temp_...', verificamos.
      final exists = _messages.any((m) => m.id == newMessage.id || 
          (m.id.startsWith('temp_') && m.content == newMessage.content && m.senderId == newMessage.senderId));
          
      if (!exists) {
        // Marcamos como leído si el mensaje no es nuestro (estamos en la pantalla)
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (newMessage.senderId != currentUserId) {
          _chatRepository.markChatAsRead(chatId); // Fire and forget
        }
        
        _messages.add(newMessage);
        notifyListeners();
      } else {
        // Reemplazar el mensaje optimista con el real para obtener el ID correcto
        final index = _messages.indexWhere((m) => m.id.startsWith('temp_') && m.content == newMessage.content);
        if (index != -1) {
          _messages[index] = newMessage;
          notifyListeners();
        }
      }
    });
  }

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _chatRepository.getMessages(chatId);
      
      // Al entrar, marcar los mensajes del otro como leídos
      await _chatRepository.markChatAsRead(chatId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Optimistic append
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = MessageEntity(
      id: tempId,
      chatId: chatId,
      senderId: currentUserId,
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _messages.add(tempMessage);
    notifyListeners();

    try {
      await _chatRepository.sendMessage(chatId: chatId, content: content);
      // El reemplazo se hará a través del realtime al recibir el mensaje real
    } catch (e) {
      // Rollback
      _messages.removeWhere((m) => m.id == tempId);
      _error = 'Error al enviar mensaje';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    Supabase.instance.client.removeChannel(Supabase.instance.client.channel('messages:$chatId'));
    super.dispose();
  }
}
