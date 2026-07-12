class ChatEntity {
  final String id;
  final String receptionId;
  final String receptionTitle;
  final String otherParticipantName;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatEntity({
    required this.id,
    required this.receptionId,
    required this.receptionTitle,
    required this.otherParticipantName,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  ChatEntity copyWith({
    String? id,
    String? receptionId,
    String? receptionTitle,
    String? otherParticipantName,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      receptionId: receptionId ?? this.receptionId,
      receptionTitle: receptionTitle ?? this.receptionTitle,
      otherParticipantName: otherParticipantName ?? this.otherParticipantName,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
