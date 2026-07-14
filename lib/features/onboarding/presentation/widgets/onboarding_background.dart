import 'dart:ui';
import 'package:flutter/material.dart';

class OnboardingBackground extends StatelessWidget {
  final Widget child;
  
  const OnboardingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Punto de luz: primario. Degradado hacia secundario (o background)
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo base (color secundario)
        Container(color: secondaryColor),
        
        // Punto de luz superior (Círculo con degradado radial)
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.6),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Punto de luz inferior
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.4),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Efecto Glassmorfismo: Blur sobre toda la pantalla
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2) 
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        
        // Contenido (encima del cristal)
        child,
      ],
    );
  }
}
