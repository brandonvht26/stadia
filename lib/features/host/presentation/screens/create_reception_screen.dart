import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/image_source_picker.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../providers/create_reception_provider.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

class CreateReceptionScreen extends StatelessWidget {
  const CreateReceptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateReceptionProvider(HostRepositoryImpl()),
      child: const _CreateReceptionView(),
    );
  }
}

class _CreateReceptionView extends StatefulWidget {
  const _CreateReceptionView();

  @override
  State<_CreateReceptionView> createState() => _CreateReceptionViewState();
}

class _CreateReceptionViewState extends State<_CreateReceptionView> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  
  LatLng? _initialLocation;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _initialLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CreateReceptionProvider>().setLocation(_initialLocation!);
      });
    } else {
      // Ubicación por defecto (Quito, Ecuador)
      setState(() {
        _initialLocation = const LatLng(-0.180653, -78.467838);
        _isLoadingLocation = false;
      });
    }
  }

  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          title: const Text('Agregar Servicio Extra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre del servicio (ej. Catering)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio (\$)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                
                if (name.isNotEmpty && price != null && price >= 0) {
                  context.read<CreateReceptionProvider>().addService(name, price);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final provider = context.read<CreateReceptionProvider>();
    if (provider.pendingPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 5 fotos por recepción.')),
      );
      return;
    }

    final pickedFile = await showImageSourcePicker(context);
    if (pickedFile != null) {
      if (context.mounted) {
        provider.addPhoto(File(pickedFile.path));
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<CreateReceptionProvider>();
      
      if (provider.selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una ubicación en el mapa.')),
        );
        return;
      }

      final result = await provider.submit();
      
      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recepción publicada exitosamente.')),
        );
        Navigator.pop(context, true);
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, ColorScheme colorScheme, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      filled: true,
      fillColor: colorScheme.surface.withOpacity(0.5),
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildGlassContainer(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface.withOpacity(0.7),
            ),
            border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateReceptionProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Publicar Recepción', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: _isLoadingLocation
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildGlassContainer(
                      context,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: _buildInputDecoration('Título', colorScheme),
                            onChanged: provider.setTitle,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _buildInputDecoration('Descripción', colorScheme),
                            maxLines: 3,
                            onChanged: provider.setDescription,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _buildInputDecoration('Precio Base (\$)', colorScheme, prefixText: '\$ '),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) => provider.setBasePrice(double.tryParse(value) ?? 0.0),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Requerido';
                              if (double.tryParse(value) == null) return 'Número inválido';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Sección del Mapa
                    Text('Ubicación (toca el mapa para fijar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface.withOpacity(0.9))),
                    const SizedBox(height: 8),
                    _buildGlassContainer(
                      context,
                      child: Container(
                        height: 250,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _initialLocation!,
                            initialZoom: 14.0,
                            onTap: (tapPosition, point) {
                              provider.setLocation(point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.stadia',
                            ),
                            if (provider.selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: provider.selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                            const RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección de Servicios
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Servicios Extra',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface.withOpacity(0.9)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _showAddServiceDialog(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Agregar', maxLines: 1),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (provider.services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No has agregado servicios extra.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                      )
                    else
                      _buildGlassContainer(
                        context,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.services.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                          itemBuilder: (context, index) {
                            final service = provider.services[index];
                            return ListTile(
                              title: Text(service.name),
                              subtitle: Text('\$${service.price.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => provider.removeService(index),
                              ),
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 24),
                    
                    // Sección de Fotos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Fotos de tu local (${provider.pendingPhotos.length}/5)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface.withOpacity(0.9)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (provider.pendingPhotos.length < 5)
                          TextButton.icon(
                            onPressed: () => _pickImage(context),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Agregar', maxLines: 1),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Límite alcanzado', style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                    if (provider.pendingPhotos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Agrega al menos una foto para mostrar tu recepción.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.pendingPhotos.length,
                          onReorder: provider.reorderPhotos,
                          itemBuilder: (context, index) {
                            final photo = provider.pendingPhotos[index];
                            return Container(
                              key: ValueKey(photo.path),
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      photo,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => provider.removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: provider.isLoading ? null : _submitForm,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: provider.isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(provider.statusText ?? 'Procesando...'),
                                ],
                              )
                            : const Text('Publicar Recepción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
