import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../discovery/domain/entities/reception_entity.dart';
import '../../data/repositories/host_repository_impl.dart';
import 'create_reception_screen.dart';
import 'verification_payment_screen.dart';
import 'manage_photos_screen.dart';
import 'bank_account_screen.dart';
import '../../../profile/screens/personal_data_screen.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

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

  Widget _buildGlassContainer(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
    return FutureBuilder<List<ReceptionEntity>>(
      future: _receptionsFuture,
      builder: (context, snapshot) {
        final receptions = snapshot.data;
        final hasReceptions = receptions != null && receptions.isNotEmpty;

        return OnboardingBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Mis Recepciones', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGlassContainer(
                        context,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 110, top: 12, bottom: 12, left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reception.title, 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Precio base: \$${reception.basePrice.toStringAsFixed(2)}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reception.latitude != null && reception.longitude != null
                                        ? 'Ubicación: ${reception.latitude!.toStringAsFixed(4)}, ${reception.longitude!.toStringAsFixed(4)}'
                                        : 'Ubicación no disponible',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.tonal(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ManagePhotosScreen.route(receptionId: reception.id),
                                              ),
                                            );
                                          },
                                          style: FilledButton.styleFrom(
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
                                          child: FilledButton(
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
                                            style: FilledButton.styleFrom(
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
                            Positioned(
                              top: 16,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: reception.isVerified ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: reception.isVerified ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      reception.isVerified ? 'Verificado' : 'No verificado',
                                      style: TextStyle(
                                        color: reception.isVerified ? Colors.green : Colors.grey,
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
          ),
        );
      },
    );
  }
}
