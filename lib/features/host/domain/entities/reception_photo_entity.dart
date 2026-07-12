class ReceptionPhotoEntity {
  final String id;
  final String mediaUrl;
  final int orderIndex;

  ReceptionPhotoEntity({
    required this.id,
    required this.mediaUrl,
    required this.orderIndex,
  });

  factory ReceptionPhotoEntity.fromJson(Map<String, dynamic> json) {
    return ReceptionPhotoEntity(
      id: json['id'] as String,
      mediaUrl: json['media_url'] as String,
      orderIndex: json['order_index'] as int,
    );
  }
}
