import 'package:flutter/material.dart';
import '../../../discovery/domain/entities/reception_entity.dart';
import '../../data/repositories/host_repository_impl.dart';
import 'create_reception_screen.dart';
import 'verification_payment_screen.dart';
import 'manage_photos_screen.dart';

class MyReceptionsScreen extends StatefulWidget {
  const MyReceptionsScreen({super.key});

  @override
  State<MyReceptionsScreen> createState() => _MyReceptionsScreenState();
}

class _MyReceptionsScreenState extends State<MyReceptionsScreen> {
  final HostRepositoryImpl _repository = HostRepositoryImpl();
  late Future<List<ReceptionEntity>> _receptionsFuture;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadReceptions();
  }

  void _loadReceptions() {
    setState(() {
      _receptionsFuture = _repository.getMyReceptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis Recepciones'),
      ),
      body: FutureBuilder<List<ReceptionEntity>>(
        future: _receptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final receptions = snapshot.data;
          if (receptions == null || receptions.isEmpty) {
            return const Center(
              child: Text('Aún no has publicado ninguna recepción.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receptions.length,
            itemBuilder: (context, index) {
              final reception = receptions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 110, top: 8, bottom: 8),
                      child: ListTile(
                        title: Text(reception.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Precio base: \$${reception.basePrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 4),
                            Text(
                              reception.latitude != null && reception.longitude != null
                                  ? 'Ubicación: ${reception.latitude!.toStringAsFixed(5)}, ${reception.longitude!.toStringAsFixed(5)}'
                                  : 'Ubicación no disponible',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManagePhotosScreen.route(receptionId: reception.id),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Gestionar fotos'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ),
                            if (!reception.isVerified) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VerificationPaymentScreen(receptionId: reception.id),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadReceptions();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: const Text('Verificar por \$20'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: reception.isVerified ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              reception.isVerified ? 'Verificado' : 'No verificado',
                              style: TextStyle(
                                color: reception.isVerified ? Colors.green.shade800 : Colors.grey.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            onPressed: _deletingIds.contains(reception.id)
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Eliminar recepción'),
                                        content: const Text('¿Eliminar esta recepción? Esta acción no se puede deshacer.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      setState(() {
                                        _deletingIds.add(reception.id);
                                      });
                                      try {
                                        await _repository.deleteReception(reception.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Recepción eliminada')),
                                          );
                                          _loadReceptions();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString().replaceAll('Exception: ', '')),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _deletingIds.remove(reception.id);
                                          });
                                        }
                                      }
                                    }
                                  },
                            icon: _deletingIds.contains(reception.id)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReceptionScreen()),
          );
          if (result == true) {
            _loadReceptions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
