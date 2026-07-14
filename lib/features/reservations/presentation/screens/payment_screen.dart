import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../data/repositories/reservations_repository_impl.dart';
import 'payment_success_screen.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

class PaymentScreen extends StatefulWidget {
  final String reservationId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.reservationId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _repository = ReservationsRepositoryImpl();
  
  String? _clientSecret;
  bool _isLoadingIntent = true;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _initPaymentIntent();
  }

  Future<void> _initPaymentIntent() async {
    try {
      final secret = await _repository.createPaymentIntent(widget.reservationId);
      setState(() {
        _clientSecret = secret;
        _isLoadingIntent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingIntent = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar el pago: $e')),
        );
      }
    }
  }

  Future<void> _handlePayment() async {
    if (_clientSecret == null) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // 1. Confirmar pago con Stripe (esto maneja el 3D Secure y valida la tarjeta usando el CardField activo)
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: _clientSecret!,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // 2. Confirmar con nuestro backend que la reserva ha sido pagada
      final confirmed = await _repository.confirmReservationPayment(widget.reservationId);

      if (confirmed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
          );
        }
      } else {
        throw Exception('El backend no pudo confirmar el pago.');
      }
    } on StripeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de Stripe: ${e.error.localizedMessage ?? e.toString()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el pago: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Widget _buildGlassContainer(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24.0),
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
          title: const Text('Pago de Reserva', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pago Seguro',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total a pagar: \$${widget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildGlassContainer(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Ingresa los datos de tu tarjeta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // CardField proporcionado por flutter_stripe
                        CardField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surface.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.primary, 
                                width: 2.0
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onCardChanged: (card) {
                            // Opcional: manejar validación del form
                          },
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 32),
                        
                        if (_isLoadingIntent)
                          const Center(
                            child: CircularProgressIndicator()
                          )
                        else
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _isProcessingPayment ? null : _handlePayment,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isProcessingPayment
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Pagar \$${widget.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: Colors.white.withOpacity(0.5), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tus datos están encriptados',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
