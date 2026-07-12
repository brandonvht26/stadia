import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/location_service.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../providers/create_reception_provider.dart';

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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (context.mounted) {
        context.read<CreateReceptionProvider>().addPhoto(File(pickedFile.path));
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateReceptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Recepción'),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: provider.setTitle,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: provider.setDescription,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Precio Base (\$)',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => provider.setBasePrice(double.tryParse(value) ?? 0.0),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Requerido';
                      if (double.tryParse(value) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Sección del Mapa
                  const Text('Ubicación (toca el mapa para fijar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                      const Text('Servicios Extra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => _showAddServiceDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  if (provider.services.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No has agregado servicios extra.'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.services.length,
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
                    
                  const SizedBox(height: 24),
                  
                  // Sección de Fotos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fotos de tu local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => _pickImage(context),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Agregar foto'),
                      ),
                    ],
                  ),
                  if (provider.pendingPhotos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Agrega al menos una foto para mostrar tu recepción.'),
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
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                    height: 50,
                    child: FilledButton(
                      onPressed: provider.isLoading ? null : _submitForm,
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
                          : const Text('Publicar Recepción'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
