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

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Oscuro premium
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),

              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Rango de Precio
                        const Text(
                'Rango de Precio',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${_minPrice.toInt()}', style: const TextStyle(color: Colors.white)),
                  Text('\$${_maxPrice.toInt()}', style: const TextStyle(color: Colors.white)),
                ],
              ),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: _absMinPrice,
                max: _absMaxPrice,
                divisions: 50,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white24,
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Calificación Mínima
              const Text(
                'Calificación Mínima',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12.0,
                children: [3.0, 4.0, 4.5].map((rating) {
                  final isSelected = _minRating == rating;
                  return ChoiceChip(
                    label: Text('$rating+ Estrellas'),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white),
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
              const Text(
                'Cercanía',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (locationDenied)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Activa tu ubicación y da permisos para filtrar por cercanía.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white),
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
              const Text(
                'Servicios Requeridos',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (availableServices.isEmpty)
                const Text('No hay servicios disponibles', style: TextStyle(color: Colors.white54))
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: availableServices.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white),
                      checkmarkColor: Colors.blueAccent,
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Limpiar', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Aplicar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
