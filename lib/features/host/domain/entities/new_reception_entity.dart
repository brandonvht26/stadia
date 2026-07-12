import 'new_service_entity.dart';

class NewReceptionEntity {
  final String title;
  final String description;
  final double basePrice;
  final double latitude;
  final double longitude;
  final List<NewServiceEntity> services;

  NewReceptionEntity({
    required this.title,
    required this.description,
    required this.basePrice,
    required this.latitude,
    required this.longitude,
    required this.services,
  });
}
