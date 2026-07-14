// Entidad que representa los filtros activos para la búsqueda de recepciones.
class DiscoveryFiltersEntity {
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? maxDistanceKm; // Radio de búsqueda geoespacial en kilómetros
  final List<String> selectedServices;
  final bool? isVerified;
  final int? minLikes;
  final int? maxLikes;
  final bool onlyLiked;

  const DiscoveryFiltersEntity({
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxDistanceKm,
    this.selectedServices = const [],
    this.isVerified,
    this.minLikes,
    this.maxLikes,
    this.onlyLiked = false,
  });

  DiscoveryFiltersEntity copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxDistanceKm,
    List<String>? selectedServices,
    bool? isVerified,
    int? minLikes,
    int? maxLikes,
    bool? onlyLiked,
    bool clearSearchQuery = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
    bool clearMaxDistanceKm = false,
    bool clearIsVerified = false,
    bool clearMinLikes = false,
    bool clearMaxLikes = false,
  }) {
    return DiscoveryFiltersEntity(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxDistanceKm: clearMaxDistanceKm ? null : (maxDistanceKm ?? this.maxDistanceKm),
      selectedServices: selectedServices ?? this.selectedServices,
      isVerified: clearIsVerified ? null : (isVerified ?? this.isVerified),
      minLikes: clearMinLikes ? null : (minLikes ?? this.minLikes),
      maxLikes: clearMaxLikes ? null : (maxLikes ?? this.maxLikes),
      onlyLiked: onlyLiked ?? this.onlyLiked,
    );
  }

  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      maxDistanceKm != null ||
      selectedServices.isNotEmpty ||
      isVerified != null ||
      minLikes != null ||
      maxLikes != null ||
      onlyLiked;
}
