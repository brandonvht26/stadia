import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/reservations_repository_impl.dart';
import '../providers/booking_provider.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final String receptionId;
  final double basePrice;

  const BookingScreen({
    super.key,
    required this.receptionId,
    required this.basePrice,
  });

  /// Factory method para construir la pantalla inyectando el BookingProvider en esta ruta
  static Widget route({required String receptionId, required double basePrice}) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = BookingProvider(ReservationsRepositoryImpl());
        provider.initForReception(receptionId, basePrice);
        return provider;
      },
      child: BookingScreen(receptionId: receptionId, basePrice: basePrice),
    );
  }

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Recepción'),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.draft == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final draft = provider.draft;
          if (draft == null) {
            return const Center(child: Text('Error al inicializar la reserva.'));
          }

          return Column(
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
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // --- Sección de Servicios ---
                    const Text(
                      'Servicios Adicionales',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (provider.availableServices.isEmpty)
                      const Text('No hay servicios adicionales disponibles.')
                    else
                      ...provider.availableServices.map((service) {
                        final isSelected = draft.selectedServices.any((s) => s.id == service.id);
                        return CheckboxListTile(
                          title: Text(service.name),
                          subtitle: Text('\$${service.price.toStringAsFixed(2)}'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            provider.toggleService(service);
                          },
                        );
                      }),
                    
                    const SizedBox(height: 24),

                    // --- Sección de Calendario ---
                    const Text(
                      'Seleccionar Fecha',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    CalendarDatePicker(
                      initialDate: draft.eventDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      currentDate: draft.eventDate, // Resalta el seleccionado (requiere workaround si falla visualmente, pero initialDate/currentDate funcionan similar)
                      onDateChanged: (DateTime date) {
                        provider.selectDate(date);
                      },
                      selectableDayPredicate: (DateTime day) {
                        // Deshabilitar días pasados
                        if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                          return false;
                        }
                        
                        // Normalizar fecha a comprobar
                        final normalizedDay = DateTime(day.year, day.month, day.day);

                        // Comprobar si está en reservedDates
                        final isReserved = provider.reservedDates.any((reserved) => 
                          reserved.year == normalizedDay.year &&
                          reserved.month == normalizedDay.month &&
                          reserved.day == normalizedDay.day
                        );

                        return !isReserved;
                      },
                    ),
                  ],
                ),
              ),

              // --- Sección Inferior de Total y Botón ---
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 16)),
                          Text(
                            '\$${draft.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: (draft.eventDate == null || provider.isLoading)
                            ? null
                            : () async {
                                final reservationId = await provider.confirmDraft();
                                if (reservationId != null) {
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentScreen(
                                          reservationId: reservationId,
                                          amount: draft.totalAmount,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: provider.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Text('Continuar al pago'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
