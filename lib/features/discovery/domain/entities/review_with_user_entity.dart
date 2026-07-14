import 'package:intl/intl.dart';

class ReviewWithUserEntity {
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewWithUserEntity({
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewWithUserEntity.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final firstName = profiles?['first_name'] as String? ?? '';
    final lastName = profiles?['last_name'] as String? ?? '';
    final userName = (firstName.isEmpty && lastName.isEmpty)
        ? 'Usuario Stadia'
        : '$firstName $lastName'.trim();

    return ReviewWithUserEntity(
      userName: userName,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(createdAt);
  }
}
