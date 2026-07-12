import 'service_entity.dart';

class BookingDraftEntity {
  final String receptionId;
  final List<ServiceEntity> selectedServices;
  final DateTime? eventDate;
  final double basePrice;

  const BookingDraftEntity({
    required this.receptionId,
    this.selectedServices = const [],
    this.eventDate,
    required this.basePrice,
  });

  double get totalAmount {
    double total = basePrice;
    for (var service in selectedServices) {
      total += service.price;
    }
    return total;
  }

  BookingDraftEntity copyWith({
    String? receptionId,
    List<ServiceEntity>? selectedServices,
    DateTime? eventDate,
    double? basePrice,
  }) {
    return BookingDraftEntity(
      receptionId: receptionId ?? this.receptionId,
      selectedServices: selectedServices ?? this.selectedServices,
      eventDate: eventDate ?? this.eventDate,
      basePrice: basePrice ?? this.basePrice,
    );
  }
}
