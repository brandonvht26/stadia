// Entidad que representa los filtros activos para la búsqueda de recepciones.
class DiscoveryFiltersEntity {
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? maxDistanceKm; // Radio de búsqueda geoespacial en kilómetros
  final List<String> selectedServices;

  const DiscoveryFiltersEntity({
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxDistanceKm,
    this.selectedServices = const [],
  });

  DiscoveryFiltersEntity copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxDistanceKm,
    List<String>? selectedServices,
    bool clearSearchQuery = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
    bool clearMaxDistanceKm = false,
  }) {
    return DiscoveryFiltersEntity(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxDistanceKm: clearMaxDistanceKm ? null : (maxDistanceKm ?? this.maxDistanceKm),
      selectedServices: selectedServices ?? this.selectedServices,
    );
  }

  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      maxDistanceKm != null ||
      selectedServices.isNotEmpty;
}
