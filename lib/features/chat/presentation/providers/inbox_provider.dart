import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class InboxProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  List<ChatEntity> _chats = [];
  List<ChatEntity> get chats => _chats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  InboxProvider(this._chatRepository) {
    _initRealtime();
  }

  RealtimeChannel? _inboxUserChannel;
  RealtimeChannel? _inboxHostChannel;

  void _initRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final suffix = currentUserId;

    void handleChatChange(PostgresChangePayload payload) {
      final eventType = payload.eventType;
      if (eventType == PostgresChangeEvent.update) {
        final newRecord = payload.newRecord;
        final id = newRecord['id'];
        final index = _chats.indexWhere((c) => c.id == id);
        
        if (index != -1) {
          final existing = _chats[index];
          final unreadCount = newRecord['user_id'] == currentUserId 
              ? newRecord['user_unread_count'] 
              : newRecord['host_unread_count'];

          _chats[index] = existing.copyWith(
            lastMessageAt: newRecord['last_message_at'] != null 
                ? DateTime.tryParse(newRecord['last_message_at']) ?? existing.lastMessageAt
                : existing.lastMessageAt,
            unreadCount: unreadCount ?? existing.unreadCount,
          );
          
          // Re-sort chats by lastMessageAt descending
          _chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          notifyListeners();
        }
      } else if (eventType == PostgresChangeEvent.insert) {
        // Need to reload to get the joined data like host/user profile info
        loadChats();
      }
    }

    _inboxUserChannel = Supabase.instance.client.channel('inbox-live-user-$suffix');
    _inboxUserChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chats',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: currentUserId,
      ),
      callback: handleChatChange,
    ).subscribe();

    _inboxHostChannel = Supabase.instance.client.channel('inbox-live-host-$suffix');
    _inboxHostChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chats',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'host_id',
        value: currentUserId,
      ),
      callback: handleChatChange,
    ).subscribe();
  }
  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _chatRepository.getMyChats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_inboxUserChannel != null) {
      Supabase.instance.client.removeChannel(_inboxUserChannel!);
    }
    if (_inboxHostChannel != null) {
      Supabase.instance.client.removeChannel(_inboxHostChannel!);
    }
    super.dispose();
  }
}
