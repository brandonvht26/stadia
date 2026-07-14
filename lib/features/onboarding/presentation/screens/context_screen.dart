import 'package:flutter/material.dart';
import 'package:stadia/features/onboarding/presentation/screens/legal_terms_screen.dart';
import '../widgets/onboarding_background.dart';

class ContextScreen extends StatelessWidget {
  const ContextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: OnboardingBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.celebration,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Encuentra el lugar perfecto',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Stadia es el marketplace donde puedes descubrir, reservar y gestionar salones y recepciones para tus eventos sociales, corporativos o familiares de manera rápida y segura.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LegalTermsScreen(),
                      ),
                    );
                  },
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
