import 'package:flutter/material.dart';
import '../../../discovery/domain/entities/reception_entity.dart';
import '../../data/repositories/host_repository_impl.dart';
import 'create_reception_screen.dart';
import 'verification_payment_screen.dart';
import 'manage_photos_screen.dart';
import 'bank_account_screen.dart';
import '../../../profile/screens/personal_data_screen.dart';

class MyReceptionsScreen extends StatefulWidget {
  const MyReceptionsScreen({super.key});

  static Future<void> handleCreateReception(BuildContext context, VoidCallback onCreated) async {
    final repository = HostRepositoryImpl();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final status = await repository.checkHostRequirements();
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading

      if (status.canCreate) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReceptionScreen()),
        );
        if (result == true) {
          onCreated();
        }
      } else {
        String message = '';
        if (!status.hasCompleteProfile && !status.hasBankAccount) {
          message = 'Completa tu perfil (nombre, apellido y teléfono) y registra tus datos bancarios antes de publicar una recepción.';
        } else if (!status.hasCompleteProfile) {
          message = 'Completa tu perfil (nombre, apellido y teléfono) antes de publicar una recepción.';
        } else {
          message = 'Registra tus datos bancarios antes de publicar una recepción.';
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Información incompleta'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (!status.hasCompleteProfile) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BankAccountScreen.route()),
                    );
                  }
                },
                child: const Text('Completar datos'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

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
    return FutureBuilder<List<ReceptionEntity>>(
      future: _receptionsFuture,
      builder: (context, snapshot) {
        final receptions = snapshot.data;
        final hasReceptions = receptions != null && receptions.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Recepciones'),
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!hasReceptions) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aún no has publicado ninguna recepción.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => MyReceptionsScreen.handleCreateReception(context, _loadReceptions),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Crear recepción'),
                      ),
                    ],
                  ),
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
                                  ? 'Ubicación: ${reception.latitude!.toStringAsFixed(4)}, ${reception.longitude!.toStringAsFixed(4)}'
                                  : 'Ubicación no disponible',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ManagePhotosScreen.route(receptionId: reception.id),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: const Text(
                                      'Fotos',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                if (!reception.isVerified) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                        minimumSize: const Size(0, 36),
                                      ),
                                      child: const Text(
                                        'Verificar \$5',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
      floatingActionButton: hasReceptions
              ? FloatingActionButton(
                  onPressed: () => MyReceptionsScreen.handleCreateReception(context, _loadReceptions),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}
