import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<String> getOrCreateChat({
    required String receptionId,
    required String hostId,
  });

  Future<List<ChatEntity>> getMyChats();

  Future<List<MessageEntity>> getMessages(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String content,
  });

  Future<void> markChatAsRead(String chatId);

  Stream<MessageEntity> subscribeToNewMessages(String chatId);
}
