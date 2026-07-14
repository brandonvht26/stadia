import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/theme/app_spacing.dart';
import '../../data/repositories/my_reservations_repository_impl.dart';
import '../providers/my_reservations_provider.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../chat/data/repositories/chat_repository_impl.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../../core/widgets/timed_confirmation_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../reservations/data/repositories/reservations_repository_impl.dart';

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
        automaticallyImplyLeading: false,
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
              padding: EdgeInsets.all(AppSpacing.scaled(context, AppSpacing.md)),
              itemCount: provider.reservations.length,
              itemBuilder: (context, index) {
                final reservation = provider.reservations[index];
                
                return Card(
                  margin: EdgeInsets.only(bottom: AppSpacing.scaled(context, AppSpacing.md)),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.scaled(context, AppSpacing.md)),
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
                            if (reservation.status == 'pending' || reservation.status == 'confirmed') ...[
                              if (reservation.rescheduleCount == 0 && reservation.eventDate.difference(DateTime.now()).inHours >= 48)
                                IconButton(
                                  icon: const Icon(Icons.event_repeat, color: Colors.blue),
                                  tooltip: 'Reagendar reserva',
                                  onPressed: () async {
                                    try {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(child: CircularProgressIndicator()),
                                      );
                                      
                                      final reservationsRepo = ReservationsRepositoryImpl();
                                      final reservedDates = await reservationsRepo.getReservedDates(reservation.receptionId);
                                      
                                      if (context.mounted) Navigator.pop(context); // Cierra loader
                                      if (!context.mounted) return;
                                      
                                      DateTime _minimumRescheduleDate() {
                                        final minDateTime = DateTime.now().add(const Duration(hours: 48));
                                        return DateTime(minDateTime.year, minDateTime.month, minDateTime.day);
                                      }
                                      
                                      final minDate = _minimumRescheduleDate();
                                      DateTime initialDate = minDate;
                                      final normalizedReserved = reservedDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
                                      
                                      while (normalizedReserved.contains(DateTime(initialDate.year, initialDate.month, initialDate.day))) {
                                        initialDate = initialDate.add(const Duration(days: 1));
                                      }
                                      
                                      final selectedDate = await showDatePicker(
                                        context: context,
                                        initialDate: initialDate,
                                        firstDate: minDate,
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        selectableDayPredicate: (day) {
                                          return !normalizedReserved.contains(DateTime(day.year, day.month, day.day));
                                        },
                                      );
                                      
                                      if (selectedDate != null && context.mounted) {
                                        final confirmed = await showTimedConfirmationDialog(
                                          context: context,
                                          title: 'Confirmar reagendamiento',
                                          message: '¿Estás seguro de reagendar tu reserva para el ${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}?',
                                          seconds: 0,
                                        );
                                        
                                        if (confirmed == true && context.mounted) {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => const Center(child: CircularProgressIndicator()),
                                          );
                                          
                                          try {
                                            await provider.rescheduleReservation(reservation.id, selectedDate);
                                            if (context.mounted) {
                                              Navigator.pop(context); // Cierra loader
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Reserva reagendada con éxito'), backgroundColor: Colors.green),
                                              );
                                              provider.loadReservations();
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              Navigator.pop(context); // Cierra loader
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Cierra loader
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al cargar disponibilidad: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                tooltip: 'Cancelar reserva',
                                onPressed: () async {
                                  final confirmed = await showTimedConfirmationDialog(
                                    context: context,
                                    title: 'Cancelar reserva',
                                    message: 'Estás a punto de cancelar esta reserva. Esta cancelación no te devolverá el dinero pagado.',
                                    seconds: 5,
                                  );
                                  if (confirmed != true) return;
                                  
                                  try {
                                    await provider.cancelReservation(reservation.id);
                                    
                                    try {
                                      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                                      if (currentUserId != null) {
                                        debugPrint('--- Intentando limpiar chat ---');
                                        debugPrint('Host ID de reserva a cancelar: ${reservation.hostId}');
                                        debugPrint('Reception ID a cancelar: ${reservation.receptionId}');
                                        
                                        await ChatRepositoryImpl().deleteChatIfNoActiveReservations(
                                          userId: currentUserId,
                                          hostId: reservation.hostId,
                                          receptionId: reservation.receptionId,
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Error al limpiar chat huérfano: $e');
                                    }
                                    
                                    provider.loadReservations();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al cancelar: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: AppSpacing.scaled(context, AppSpacing.sm)),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Text(
                              '${reservation.eventDate.day.toString().padLeft(2, '0')}/${reservation.eventDate.month.toString().padLeft(2, '0')}/${reservation.eventDate.year}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.scaled(context, AppSpacing.xs)),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Text(
                              reservation.totalAmount.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        // Sección de Reseñas (solo si completada)
                        if (reservation.status == 'completed') ...[
                          SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
                          const Divider(),
                          SizedBox(height: AppSpacing.scaled(context, AppSpacing.sm)),
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
                          SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
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
