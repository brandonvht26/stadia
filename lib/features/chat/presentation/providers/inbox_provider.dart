import 'package:flutter/foundation.dart';
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

  InboxProvider(this._chatRepository);

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
}
