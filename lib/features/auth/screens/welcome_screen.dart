import 'package:flutter/material.dart';
import 'package:stadia/core/theme/app_colors.dart';
import 'package:stadia/features/auth/screens/login_screen.dart';
import 'package:stadia/features/auth/screens/register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image (Simulando una recepción premium)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=2098&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay gradiente para asegurar la legibilidad del texto
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Título Principal
                  Text(
                    'Stadia',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Subtítulo
                  Text(
                    'Encuentra y reserva la recepción perfecta para tu evento inolvidable.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 48),
                  // Botón Empezar / Registro
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Comenzar ahora'),
                  ),
                  const SizedBox(height: 16),
                  // Botón Iniciar Sesión (Glassmorfismo/Outlined)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ya tengo una cuenta'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
