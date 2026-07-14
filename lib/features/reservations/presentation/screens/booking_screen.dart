import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/reservations_repository_impl.dart';
import '../providers/booking_provider.dart';
import 'payment_screen.dart';
import '../../../../core/widgets/timed_confirmation_dialog.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

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
        Future.microtask(() => provider.initForReception(receptionId, basePrice));
        return provider;
      },
      child: BookingScreen(receptionId: receptionId, basePrice: basePrice),
    );
  }

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _firstAvailableDate(List<DateTime> reservedDates) {
    DateTime candidate = DateTime.now();
    final normalizedReserved = reservedDates.map((d) => 
        DateTime(d.year, d.month, d.day)).toSet();
    
    while (normalizedReserved.contains(DateTime(candidate.year, candidate.month, 
        candidate.day))) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return DateTime(candidate.year, candidate.month, candidate.day);
  }

  Widget _buildGlassContainer(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
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
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Reservar Recepción', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    color: colorScheme.error,
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: colorScheme.onError),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // --- Sección de Servicios ---
                      Text(
                        'Servicios Adicionales',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      if (provider.availableServices.isEmpty)
                        Text('No hay servicios adicionales disponibles.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)))
                      else
                        _buildGlassContainer(
                          context,
                          child: Column(
                            children: provider.availableServices.map((service) {
                              final isSelected = draft.selectedServices.any((s) => s.id == service.id);
                              return CheckboxListTile(
                                title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('\$${service.price.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                                value: isSelected,
                                activeColor: colorScheme.primary,
                                checkColor: colorScheme.onPrimary,
                                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (bool? value) {
                                  provider.toggleService(service);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      
                      const SizedBox(height: 32),

                      // --- Sección de Calendario ---
                      Text(
                        'Seleccionar Fecha',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassContainer(
                        context,
                        padding: const EdgeInsets.all(8.0),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: colorScheme.copyWith(
                              surface: Colors.transparent,
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: draft.eventDate ?? _firstAvailableDate(provider.reservedDates),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            currentDate: draft.eventDate, // Resalta el seleccionado
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
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Sección Inferior de Total y Botón ---
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.8),
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Total:', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.7))),
                                Text(
                                  '\$${draft.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: FilledButton(
                                  onPressed: (draft.eventDate == null || provider.isLoading)
                                      ? null
                                        : () async {
                                            final confirmed = await showTimedConfirmationDialog(
                                              context: context,
                                              title: 'Confirmar reserva',
                                              message: 'Estás por hacer una reserva en este lugar. La decisión es definitiva: en caso de arrepentirte, no habrá reembolso del dinero.',
                                              seconds: 10,
                                            );
                                            if (confirmed != true) return;

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
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: provider.isLoading 
                                    ? SizedBox(
                                        width: 24, 
                                        height: 24, 
                                        child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)
                                      ) 
                                    : const Text(
                                        'Continuar al pago', 
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
