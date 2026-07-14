import 'dart:async';
import 'dart:ui';
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
  bool _isSearchExpanded = false;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            height: 48,
                            alignment: _isSearchExpanded ? Alignment.center : Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: _isSearchExpanded
                                ? TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    autofocus: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar locales o anfitriones...',
                                      hintStyle: const TextStyle(color: Colors.white70),
                                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _isSearchExpanded = false;
                                            _searchController.clear();
                                          });
                                          _onSearchChanged('');
                                        },
                                      ),
                                      filled: false,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isSearchExpanded = true;
                                      });
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.search, color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (!_isSearchExpanded) const SizedBox(width: 12),
                    if (!_isSearchExpanded)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: provider.currentFilters.hasActiveFilters 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: provider.currentFilters.hasActiveFilters
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.tune,
                                color: Colors.white,
                              ),
                              onPressed: _showFiltersSheet,
                            ),
                          ),
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
