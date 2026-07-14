import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

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

  Widget _buildGlassContainer(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface.withOpacity(0.8),
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
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Verificar Recepción', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGlassContainer(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.credit_card, size: 48, color: colorScheme.primary.withOpacity(0.8)),
                    const SizedBox(height: 16),
                    Text(
                      'Ingresa los datos de tu tarjeta para verificar tu recepción',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: CardField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                        onCardChanged: (card) {},
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    if (_isLoadingIntent)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _isProcessingPayment ? null : _handlePayment,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isProcessingPayment
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Procesando...'),
                                  ],
                                )
                              : const Text(
                                  'Pagar \$5.00',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
