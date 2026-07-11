// Entidad base que representa una recepción en el dominio de la aplicación.
// Esta clase no debe tener dependencias de Flutter ni librerías externas.

class ReceptionEntity {
  final String id;
  final String hostId;
  final String title;
  final String? description;
  final double basePrice;
  final double? latitude;
  final double? longitude;
  final bool isVerified;
  final int likesCount;
  final List<String> imageUrls;
  final bool isLikedByUser;
  final double avgRating;
  final int reviewsCount;
  final List<String> services;
  
  // Propiedad transitoria calculada en memoria por el cliente (LocationService)
  final double? distanceKm;

  ReceptionEntity({
    required this.id,
    required this.hostId,
    required this.title,
    this.description,
    required this.basePrice,
    this.latitude,
    this.longitude,
    required this.isVerified,
    required this.likesCount,
    required this.imageUrls,
    this.isLikedByUser = false,
    this.avgRating = 0.0,
    this.reviewsCount = 0,
    this.services = const [],
    this.distanceKm,
  });

  ReceptionEntity copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    double? basePrice,
    double? latitude,
    double? longitude,
    bool? isVerified,
    int? likesCount,
    List<String>? imageUrls,
    bool? isLikedByUser,
    double? avgRating,
    int? reviewsCount,
    List<String>? services,
    double? distanceKm,
  }) {
    return ReceptionEntity(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      likesCount: likesCount ?? this.likesCount,
      imageUrls: imageUrls ?? this.imageUrls,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      avgRating: avgRating ?? this.avgRating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      services: services ?? this.services,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
