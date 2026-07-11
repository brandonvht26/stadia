import '../entities/reception_entity.dart';
import '../entities/discovery_filters_entity.dart';

// Puerto (interfaz) para el repositorio de Discovery en la capa de Dominio.
// Define los contratos para la obtención de datos, aislados de la implementación.

abstract class DiscoveryRepository {
  /// Obtiene una lista de recepciones con soporte para paginación y filtros opcionales.
  Future<List<ReceptionEntity>> getReceptions({
    required int page,
    required int pageSize,
    DiscoveryFiltersEntity? filters,
  });

  /// Obtiene todos los servicios disponibles únicos para poblar los filtros.
  Future<List<String>> getAvailableServices();

  /// Dar "me gusta" a una recepción
  /// Da 'me gusta' a una recepción. Usa el usuario actualmente autenticado.
  Future<void> likeReception(String receptionId);

  /// Quita el 'me gusta' de una recepción. Usa el usuario actualmente autenticado.
  Future<void> unlikeReception(String receptionId);
}
