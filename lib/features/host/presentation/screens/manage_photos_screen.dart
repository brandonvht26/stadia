import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../providers/manage_photos_provider.dart';

class ManagePhotosScreen extends StatefulWidget {
  final String receptionId;

  const ManagePhotosScreen({
    super.key,
    required this.receptionId,
  });

  static Widget route({required String receptionId}) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ManagePhotosProvider(HostRepositoryImpl(), receptionId);
        Future.microtask(() => provider.loadPhotos());
        return provider;
      },
      child: ManagePhotosScreen(receptionId: receptionId),
    );
  }

  @override
  State<ManagePhotosScreen> createState() => _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends State<ManagePhotosScreen> {
  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (context.mounted) {
        context.read<ManagePhotosProvider>().addPhoto(File(pickedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagePhotosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Fotos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: provider.isSaving ? null : () => _pickImage(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.photos.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay fotos. Agrega algunas.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: provider.isSaving ? null : () => _pickImage(context),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Agregar foto'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                if (provider.error != null)
                  Container(
                    color: Colors.redAccent,
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: provider.photos.length,
                      onReorder: provider.reorderPhotos,
                      itemBuilder: (context, index) {
                        final photo = provider.photos[index];
                        return Card(
                          key: ValueKey(photo.id),
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Image.network(
                                photo.mediaUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: provider.isSaving ? null : () => provider.deletePhoto(index),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Orden: ${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          
          if (provider.isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
