import 'package:flutter/material.dart';

class AppColors {
  // Primario
  static const Color primary = Color(0xFF6D1432); // Concha de Vino
  static const Color primaryLight = Color(0xFF8B1C43);
  static const Color primaryDark = Color(0xFF4A0D22);

  // Fondos y Superficies
  static const Color background = Color(0xFFF6F4F0); // Perla
  static const Color surface = Color(0xFFFFFFFF); // Blanco

  // Textos
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // Estados
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);

  // --- MODO OSCURO ---
  // Primario Oscuro (Vino Neón / Luminous Ruby)
  // En modo oscuro, el vino oscuro pierde contraste. Se usa una versión más vibrante y luminosa.
  static const Color primaryNeon = Color(0xFFE01A4F); 

  // Fondos y Superficies Oscuras
  static const Color backgroundDark = Color(0xFF121212); // Negro Premium
  static const Color surfaceDark = Color(0xFF1E1E1E); // Gris oscuro para tarjetas

  // Textos Oscuros
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
}
