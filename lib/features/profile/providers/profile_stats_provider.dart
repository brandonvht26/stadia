import 'package:flutter/material.dart';
import '../../discovery/domain/entities/reception_entity.dart';
import '../../host/data/repositories/host_repository_impl.dart';
import '../../my_reservations/data/repositories/my_reservations_repository_impl.dart';
import '../../my_reservations/domain/entities/reservation_entity.dart';

class ProfileStatsProvider extends ChangeNotifier {
  final HostRepositoryImpl _hostRepository = HostRepositoryImpl();
  final MyReservationsRepositoryImpl _reservationsRepository = MyReservationsRepositoryImpl();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<ReceptionEntity> _myReceptions = [];
  List<ReceptionEntity> get myReceptions => _myReceptions;

  int _reservationsCount = 0;
  int get reservationsCount => _reservationsCount;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final receptionsFuture = _hostRepository.getMyReceptions();
      final reservationsFuture = _reservationsRepository.getMyReservations();

      final results = await Future.wait([receptionsFuture, reservationsFuture]);

      _myReceptions = results[0] as List<ReceptionEntity>;
      final reservations = results[1] as List<ReservationEntity>;
      _reservationsCount = reservations.length;
    } catch (e) {
      _error = 'Error al cargar estadísticas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getMemberSinceFormatted(String? createdAtString) {
    if (createdAtString == null || createdAtString.isEmpty) return 'Miembro';

    try {
      final date = DateTime.parse(createdAtString);
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      final monthName = months[date.month - 1];
      return 'Miembro desde $monthName ${date.year}';
    } catch (e) {
      return 'Miembro';
    }
  }
}
