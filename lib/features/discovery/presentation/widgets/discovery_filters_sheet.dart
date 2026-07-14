import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discovery_provider.dart';

class DiscoveryFiltersSheet extends StatefulWidget {
  const DiscoveryFiltersSheet({super.key});

  @override
  State<DiscoveryFiltersSheet> createState() => _DiscoveryFiltersSheetState();
}

class _DiscoveryFiltersSheetState extends State<DiscoveryFiltersSheet> {
  late double _minPrice;
  late double _maxPrice;
  double? _minRating;
  double? _maxDistanceKm;
  final Set<String> _selectedServices = {};
  bool? _isVerified;
  bool _sortByPopularity = false;
  bool _onlyLiked = false;

  final double _absMinPrice = 0.0;
  final double _absMaxPrice = 5000.0; // O un límite realista según la DB

  @override
  void initState() {
    super.initState();
    final currentFilters = context.read<DiscoveryProvider>().currentFilters;
    _minPrice = currentFilters.minPrice ?? _absMinPrice;
    _maxPrice = currentFilters.maxPrice ?? _absMaxPrice;
    _minRating = currentFilters.minRating;
    _maxDistanceKm = currentFilters.maxDistanceKm;
    _selectedServices.addAll(currentFilters.selectedServices);
    _isVerified = currentFilters.isVerified;
    _sortByPopularity = currentFilters.sortByPopularity;
    _onlyLiked = currentFilters.onlyLiked;
  }

  void _applyFilters() {
    final provider = context.read<DiscoveryProvider>();
    final currentFilters = provider.currentFilters;

    final newFilters = currentFilters.copyWith(
      minPrice: _minPrice > _absMinPrice ? _minPrice : null,
      clearMinPrice: _minPrice <= _absMinPrice,
      maxPrice: _maxPrice < _absMaxPrice ? _maxPrice : null,
      clearMaxPrice: _maxPrice >= _absMaxPrice,
      minRating: _minRating,
      clearMinRating: _minRating == null,
      maxDistanceKm: _maxDistanceKm,
      clearMaxDistanceKm: _maxDistanceKm == null,
      selectedServices: _selectedServices.toList(),
      isVerified: _isVerified,
      clearIsVerified: _isVerified == null,
      sortByPopularity: _sortByPopularity,
      clearSortByPopularity: !_sortByPopularity,
      onlyLiked: _onlyLiked,
    );

    provider.updateFilters(newFilters);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    context.read<DiscoveryProvider>().clearFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoveryProvider>();
    final availableServices = provider.availableServices;
    final locationDenied = provider.locationPermissionDenied;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.1), colorScheme.surface.withValues(alpha: 0.85)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros',
                    style: textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: colorScheme.onSurface.withOpacity(0.08)),

              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Rango de Precio
                        Text(
                          'Rango de Precio',
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${_minPrice.toInt()}', style: textTheme.bodyMedium),
                            Text('\$${_maxPrice.toInt()}', style: textTheme.bodyMedium),
                          ],
                        ),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: _absMinPrice,
                max: _absMaxPrice,
                divisions: 50,
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.primary.withOpacity(0.2),
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Verificación
              Text(
                'Verificación',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _isVerified == null,
                    selectedColor: colorScheme.primary.withOpacity(0.12),
                    backgroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isVerified == null ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _isVerified == null ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: _isVerified == null ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _isVerified = null);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Solo verificados'),
                    selected: _isVerified == true,
                    selectedColor: colorScheme.primary.withOpacity(0.12),
                    backgroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isVerified == true ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _isVerified == true ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: _isVerified == true ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _isVerified = true);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Solo no verificados'),
                    selected: _isVerified == false,
                    selectedColor: colorScheme.primary.withOpacity(0.12),
                    backgroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _isVerified == false ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _isVerified == false ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: _isVerified == false ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) setState(() => _isVerified = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Likes / Popularidad
              SwitchListTile(
                title: Text('Ordenar por los más populares', style: textTheme.titleSmall),
                value: _sortByPopularity,
                onChanged: (val) {
                  setState(() {
                    _sortByPopularity = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Favoritos
              SwitchListTile(
                title: Text('Solo mostrar los que me gustan', style: textTheme.titleSmall),
                value: _onlyLiked,
                onChanged: (val) {
                  setState(() {
                    _onlyLiked = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Calificación Mínima
              Text(
                'Calificación Mínima',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0,
                children: [3.0, 4.0, 4.5].map((rating) {
                  final isSelected = _minRating == rating;
                  return ChoiceChip(
                    label: Text('$rating+ Estrellas'),
                    selected: isSelected,
                    selectedColor: colorScheme.primary.withOpacity(0.12),
                    backgroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      setState(() {
                        _minRating = selected ? rating : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Cercanía (Geolocalización)
              Text(
                'Cercanía',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              if (locationDenied)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    border: Border.all(color: colorScheme.error.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Activa tu ubicación y da permisos para filtrar por cercanía.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 12.0,
                  children: [null, 5.0, 10.0, 25.0, 50.0].map((distance) {
                    final isSelected = _maxDistanceKm == distance;
                    final label = distance == null ? 'Cualquiera' : '${distance.toInt()} km';
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: colorScheme.primary.withOpacity(0.12),
                      backgroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _maxDistanceKm = selected ? distance : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Servicios
              Text(
                'Servicios Requeridos',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              if (availableServices.isEmpty)
                Text('No hay servicios disponibles', style: textTheme.bodyMedium)
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: availableServices.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      selectedColor: colorScheme.primary.withOpacity(0.12),
                      backgroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      checkmarkColor: colorScheme.primary,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )));
  }
}
