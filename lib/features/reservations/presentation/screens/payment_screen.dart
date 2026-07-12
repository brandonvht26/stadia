import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../data/repositories/reservations_repository_impl.dart';
import 'payment_success_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Reserva'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresa los datos de tu tarjeta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // CardField proporcionado por flutter_stripe
            CardField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                ),
              ),
              onCardChanged: (card) {
                // Opcional: manejar validación del form
              },
            ),
            const SizedBox(height: 32),
            
            if (_isLoadingIntent)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _isProcessingPayment ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Pagar \$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
