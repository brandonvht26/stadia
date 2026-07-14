import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../data/repositories/host_repository_impl.dart';

class VerificationPaymentScreen extends StatefulWidget {
  final String receptionId;

  const VerificationPaymentScreen({
    super.key,
    required this.receptionId,
  });

  @override
  State<VerificationPaymentScreen> createState() => _VerificationPaymentScreenState();
}

class _VerificationPaymentScreenState extends State<VerificationPaymentScreen> {
  final _repository = HostRepositoryImpl();
  
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
      final secret = await _repository.createVerificationPaymentIntent(widget.receptionId);
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
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: _clientSecret!,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      final confirmed = await _repository.confirmVerificationPayment(widget.receptionId);

      if (confirmed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago exitoso. Recepción verificada.')),
          );
          Navigator.pop(context, true);
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
        title: const Text('Verificar Recepción'),
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
            
            CardField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                ),
              ),
              onCardChanged: (card) {},
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
                    : const Text(
                        'Pagar \$5.00',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
