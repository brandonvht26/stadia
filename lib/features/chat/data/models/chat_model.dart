import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.receptionId,
    required super.receptionTitle,
    required super.otherParticipantName,
    super.otherParticipantAvatarUrl,
    required super.lastMessageAt,
    required super.unreadCount,
  });

  /// Crea un modelo desde JSON, calculando `otherParticipantName` y `unreadCount`
  /// basado en los joins devueltos por Supabase y el `currentUserId`.
  factory ChatModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final hostId = json['host_id'] as String;
    
    // Determinar con quién estamos hablando
    final isHost = currentUserId == hostId;
    
    // Extraer los perfiles de los joins
    final hostProfile = json['host_profile'] as Map<String, dynamic>?;
    final userProfile = json['user_profile'] as Map<String, dynamic>?;
    
    String otherName = 'Usuario Desconocido';
    String? otherAvatarUrl;
    
    if (isHost && userProfile != null) {
      otherName = '${userProfile['first_name']} ${userProfile['last_name']}';
      otherAvatarUrl = userProfile['avatar_url'] as String?;
    } else if (!isHost && hostProfile != null) {
      otherName = '${hostProfile['first_name']} ${hostProfile['last_name']}';
      otherAvatarUrl = hostProfile['avatar_url'] as String?;
    }

    final receptionData = json['receptions'] as Map<String, dynamic>?;
    final title = receptionData != null ? receptionData['title'] as String : 'Recepción desconocida';

    // Calcular el unreadCount si messages viene en el join
    int unreadCount = 0;
    if (json.containsKey('messages')) {
      final messagesList = json['messages'] as List<dynamic>;
      unreadCount = messagesList.where((m) {
        final mSender = m['sender_id'] as String;
        final mRead = m['is_read'] as bool? ?? true;
        return mSender != currentUserId && !mRead;
      }).length;
    }

    return ChatModel(
      id: json['id'] as String,
      receptionId: json['reception_id'] as String,
      receptionTitle: title,
      otherParticipantName: otherName,
      otherParticipantAvatarUrl: otherAvatarUrl,
      lastMessageAt: DateTime.parse(json['last_message_at'].toString()),
      unreadCount: unreadCount,
    );
  }
}
