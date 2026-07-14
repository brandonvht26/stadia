class ReservationEntity {
  final String id;
  final String receptionId;
  final String receptionTitle;
  final String hostId;
  final DateTime eventDate;
  final double totalAmount;
  final String status;
  final bool hasReview;
  final int rescheduleCount;

  const ReservationEntity({
    required this.id,
    required this.receptionId,
    required this.receptionTitle,
    required this.hostId,
    required this.eventDate,
    required this.totalAmount,
    required this.status,
    this.hasReview = false,
    this.rescheduleCount = 0,
  });

  ReservationEntity copyWith({
    String? id,
    String? receptionId,
    String? receptionTitle,
    String? hostId,
    DateTime? eventDate,
    double? totalAmount,
    String? status,
    bool? hasReview,
    int? rescheduleCount,
  }) {
    return ReservationEntity(
      id: id ?? this.id,
      receptionId: receptionId ?? this.receptionId,
      receptionTitle: receptionTitle ?? this.receptionTitle,
      hostId: hostId ?? this.hostId,
      eventDate: eventDate ?? this.eventDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      hasReview: hasReview ?? this.hasReview,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
    );
  }
}
