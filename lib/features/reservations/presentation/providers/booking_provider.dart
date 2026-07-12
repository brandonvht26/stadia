import 'package:flutter/material.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/booking_draft_entity.dart';
import '../../domain/repositories/reservations_repository.dart';

class BookingProvider extends ChangeNotifier {
  final ReservationsRepository _repository;

  BookingProvider(this._repository);

  BookingDraftEntity? _draft;
  BookingDraftEntity? get draft => _draft;

  List<ServiceEntity> _availableServices = [];
  List<ServiceEntity> get availableServices => _availableServices;

  List<DateTime> _reservedDates = [];
  List<DateTime> get reservedDates => _reservedDates;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Inicializa el estado para una recepción en particular
  Future<void> initForReception(String receptionId, double basePrice) async {
    _isLoading = true;
    _error = null;
    _draft = BookingDraftEntity(receptionId: receptionId, basePrice: basePrice);
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getServicesForReception(receptionId),
        _repository.getReservedDates(receptionId),
      ]);

      _availableServices = results[0] as List<ServiceEntity>;
      _reservedDates = results[1] as List<DateTime>;
    } catch (e) {
      _error = 'Error al cargar datos de reserva: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega o quita un servicio del borrador
  void toggleService(ServiceEntity service) {
    if (_draft == null) return;

    final currentServices = List<ServiceEntity>.from(_draft!.selectedServices);
    
    if (currentServices.any((s) => s.id == service.id)) {
      currentServices.removeWhere((s) => s.id == service.id);
    } else {
      currentServices.add(service);
    }

    _draft = _draft!.copyWith(selectedServices: currentServices);
    notifyListeners();
  }

  /// Selecciona una fecha, validando que no esté reservada
  void selectDate(DateTime date) {
    if (_draft == null) return;

    // Normalizar a UTC sin hora para comparar correctamente
    final normalizedSelected = DateTime(date.year, date.month, date.day);
    
    final isBlocked = _reservedDates.any((d) => 
      d.year == normalizedSelected.year &&
      d.month == normalizedSelected.month &&
      d.day == normalizedSelected.day
    );

    if (!isBlocked) {
      _draft = _draft!.copyWith(eventDate: normalizedSelected);
      notifyListeners();
    } else {
      _error = 'La fecha seleccionada ya no está disponible.';
      notifyListeners();
    }
  }

  /// Confirma el borrador llamando al repositorio y retorna el ID de la reserva
  Future<String?> confirmDraft() async {
    if (_draft == null || _draft!.eventDate == null) {
      _error = 'Debes seleccionar una fecha para continuar.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reservationId = await _repository.createPendingReservation(
        receptionId: _draft!.receptionId,
        eventDate: _draft!.eventDate!,
        services: _draft!.selectedServices,
        totalAmount: _draft!.totalAmount,
      );

      return reservationId;
    } catch (e) {
      _error = 'Error al confirmar la reserva: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
