import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.receptionId,
    required super.name,
    required super.price,
    super.iconUrl,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      receptionId: json['reception_id'] as String,
      name: json['name'] as String,
      // Manejo de double/int de Supabase
      price: (json['price'] as num).toDouble(),
      iconUrl: json['icon_url'] as String?,
    );
  }
}
