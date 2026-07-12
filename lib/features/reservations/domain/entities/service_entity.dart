class ServiceEntity {
  final String id;
  final String receptionId;
  final String name;
  final double price;
  final String? iconUrl;

  const ServiceEntity({
    required this.id,
    required this.receptionId,
    required this.name,
    required this.price,
    this.iconUrl,
  });
}
