import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discovery_provider.dart';
import '../widgets/reception_card.dart';
import '../widgets/discovery_filters_sheet.dart';

// Pantalla principal del feature de Discovery (Feed estilo TikTok).

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Iniciar la carga de datos luego del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DiscoveryProvider>();
      provider.loadMoreReceptions();
      _searchController.text = provider.currentFilters.searchQuery ?? '';
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final provider = context.read<DiscoveryProvider>();
      provider.updateFilters(provider.currentFilters.copyWith(
        searchQuery: query,
        clearSearchQuery: query.trim().isEmpty,
      ));
    });
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiscoveryFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro inmersivo
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, child) {
          Widget content;

          // Estado: Inicial de Carga
          if (provider.receptions.isEmpty && provider.isLoading) {
            content = const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          // Estado: Error Inicial
          else if (provider.receptions.isEmpty && provider.error != null) {
            content = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshFeed(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          // Estado: Lista Vacía (con o sin filtros)
          else if (provider.receptions.isEmpty) {
            content = RefreshIndicator(
              onRefresh: () => provider.refreshFeed(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(
                    child: Text(
                      'No hay recepciones disponibles.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  if (provider.currentFilters.hasActiveFilters) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          provider.clearFilters();
                        },
                        icon: const Icon(Icons.clear_all, color: Colors.blueAccent),
                        label: const Text(
                          'Limpiar filtros',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          // Estado: Mostrando Feed Normal
          else {
            content = RefreshIndicator(
              onRefresh: () => provider.refreshFeed(),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical, // Scroll vertical estilo feed infinito
                itemCount: provider.receptions.length + (provider.hasMore ? 1 : 0),
                onPageChanged: (index) {
                  // Al llegar cerca del final (últimas 2-3 tarjetas), solicitar más.
                  if (index >= provider.receptions.length - 3) {
                    provider.loadMoreReceptions();
                  }
                },
                itemBuilder: (context, index) {
                  if (index == provider.receptions.length) {
                    // Indicador de carga al final de la lista
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final reception = provider.receptions[index];
                  return ReceptionCard(
                    key: ValueKey(reception.id),
                    reception: reception,
                    onLikeToggle: () => provider.toggleLike(reception.id),
                  );
                },
              ),
            );
          }

          // El Stack asegura que la capa de Búsqueda y Filtros siempre flote por encima del contenido
          return Stack(
            children: [
              content,
              
              // Capa de Búsqueda y Filtros superior
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar locales o anfitriones...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.6),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: provider.currentFilters.hasActiveFilters 
                            ? Colors.blueAccent 
                            : Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: provider.currentFilters.hasActiveFilters 
                              ? Colors.white 
                              : Colors.white70,
                        ),
                        onPressed: _showFiltersSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
