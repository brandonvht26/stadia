import '../../domain/entities/reception_entity.dart';

// Modelo de datos para Reception, encargado de la serialización y deserialización
// desde fuentes externas como Supabase (JSON).

class ReceptionModel extends ReceptionEntity {
  ReceptionModel({
    required super.id,
    required super.hostId,
    required super.title,
    super.description,
    required super.basePrice,
    super.latitude,
    super.longitude,
    required super.isVerified,
    required super.likesCount,
    required super.imageUrls,
    super.isLikedByUser,
    super.avgRating,
    super.reviewsCount,
    super.services,
    super.distanceKm,
  });

  factory ReceptionModel.fromJson(Map<String, dynamic> json, {bool isLikedByUser = false}) {
    // Extraer y ordenar la lista de medios si existe
    List<String> parsedImageUrls = [];
    if (json['reception_media'] != null && json['reception_media'] is List) {
      final List<dynamic> mediaList = json['reception_media'];
      
      // Ordenar por order_index
      mediaList.sort((a, b) {
        final int orderA = (a['order_index'] as num?)?.toInt() ?? 0;
        final int orderB = (b['order_index'] as num?)?.toInt() ?? 0;
        return orderA.compareTo(orderB);
      });

      // Mapear solo la URL
      parsedImageUrls = mediaList
          .map((item) => item['media_url'] as String?)
          .where((url) => url != null)
          .cast<String>()
          .toList();
    }

    // Parseo de la ubicación (asumimos columnas sueltas lat/lng o un objeto JSON interno).
    double? parsedLat;
    double? parsedLng;
    if (json['location'] != null && json['location'] is Map) {
      parsedLat = (json['location']['lat'] as num?)?.toDouble();
      parsedLng = (json['location']['lng'] as num?)?.toDouble();
    } else {
      parsedLat = (json['latitude'] as num?)?.toDouble();
      parsedLng = (json['longitude'] as num?)?.toDouble();
    }

    // Extraer la lista de servicios
    List<String> parsedServices = [];
    if (json['services'] != null && json['services'] is List) {
      final servicesList = json['services'] as List;
      parsedServices = servicesList
          .map((s) => s['name'] as String?)
          .where((s) => s != null)
          .cast<String>()
          .toList();
    }

    return ReceptionModel(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      latitude: parsedLat,
      longitude: parsedLng,
      isVerified: json['is_verified'] as bool? ?? false,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      imageUrls: parsedImageUrls,
      isLikedByUser: isLikedByUser,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      services: parsedServices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'title': title,
      'description': description,
      'base_price': basePrice,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
      'likes_count': likesCount,
    };
  }
}
