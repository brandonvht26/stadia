import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/my_reservations_repository_impl.dart';
import '../providers/my_reservations_provider.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../chat/data/repositories/chat_repository_impl.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  /// Factory method para inyectar el Provider específico a esta ruta
  static Widget route() {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = MyReservationsProvider(MyReservationsRepositoryImpl());
        Future.microtask(() => provider.loadReservations());
        return provider;
      },
      child: const MyReservationsScreen(),
    );
  }

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
      ),
      body: Consumer<MyReservationsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadReservations(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.reservations.isEmpty) {
            return const Center(
              child: Text(
                'No tienes reservas todavía.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadReservations,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.reservations.length,
              itemBuilder: (context, index) {
                final reservation = provider.reservations[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                reservation.receptionTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(reservation.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(reservation.status)),
                              ),
                              child: Text(
                                _formatStatus(reservation.status),
                                style: TextStyle(
                                  color: _getStatusColor(reservation.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '${reservation.eventDate.day.toString().padLeft(2, '0')}/${reservation.eventDate.month.toString().padLeft(2, '0')}/${reservation.eventDate.year}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              reservation.totalAmount.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        // Sección de Reseñas (solo si completada)
                        if (reservation.status == 'completed') ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (reservation.hasReview)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Ya calificaste esta recepción',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReviewScreen(
                                        receptionId: reservation.receptionId,
                                        receptionTitle: reservation.receptionTitle,
                                      ),
                                    ),
                                  );
                                  
                                  // Si la reseña se envió con éxito, refrescamos la lista
                                  if (result == true) {
                                    provider.loadReservations();
                                  }
                                },
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Dejar reseña'),
                              ),
                            ),
                        ],
                        
                        // Botón de Chat (siempre que no esté cancelada)
                        if (reservation.status != 'cancelled') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  // Mostrar un indicador de carga si lo deseas, aquí es sincrónico pero getOrCreateChat toma tiempo
                                  final chatRepo = ChatRepositoryImpl();
                                  final chatId = await chatRepo.getOrCreateChat(
                                    receptionId: reservation.receptionId,
                                    hostId: reservation.hostId,
                                  );
                                  
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatThreadScreen.route(
                                          chatId: chatId,
                                          // Como no tenemos el nombre del host aquí, enviamos un placeholder o el título de la recepción
                                          otherParticipantName: 'Chat de ${reservation.receptionTitle}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al iniciar chat: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Chatear con el host'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
