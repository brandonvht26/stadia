import 'package:flutter/material.dart';
import 'package:stadia/core/services/onboarding_service.dart';
import 'package:stadia/features/auth/screens/login_screen.dart';

class LegalTermsScreen extends StatefulWidget {
  const LegalTermsScreen({super.key});

  @override
  State<LegalTermsScreen> createState() => _LegalTermsScreenState();
}

class _LegalTermsScreenState extends State<LegalTermsScreen> {
  bool _acceptedTerms = false;

  void _onAcceptAndContinue() async {
    await OnboardingService.markOnboardingSeen();
    if (!mounted) return;
    
    // Navegar a LoginScreen limpiando el stack de onboarding
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      '''Términos y Condiciones de Uso de Stadia

Bienvenido a Stadia. Al utilizar nuestra aplicación, aceptas los siguientes términos:

1. Naturaleza del Servicio: Stadia actúa exclusivamente como una plataforma intermediaria (marketplace) que conecta a anfitriones (dueños de salones y recepciones) con usuarios que buscan espacios para eventos.

2. Responsabilidad: Stadia no es propietario, operador ni proveedor de los espacios ofrecidos. Por lo tanto, Stadia no se hace responsable por daños, conflictos, accidentes, o incidentes de cualquier tipo ocurridos antes, durante o después de los eventos organizados a través de la plataforma.

3. Acuerdos Directos: Cualquier acuerdo, contrato o disputa relacionada con el uso del espacio es estrictamente entre el usuario y el anfitrión.

Al continuar, confirmas que has leído y aceptas nuestra política de intermediación y limitación de responsabilidad.''',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'He leído y acepto los términos y condiciones',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _acceptedTerms ? _onAcceptAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Aceptar y continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
