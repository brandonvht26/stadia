import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class OnboardingService {
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _termsPendingKey = 'terms_accepted_pending_sync';

  /// Verifica si el usuario ya vio el onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Marca el onboarding como visto y guarda el flag local de términos pendientes
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    await prefs.setBool(_termsPendingKey, true);
  }

  /// Sincroniza la aceptación de términos con Supabase si está pendiente
  static Future<void> syncTermsAccepted(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPendingSync = prefs.getBool(_termsPendingKey) ?? false;

      if (hasPendingSync) {
        await Supabase.instance.client.from('profiles').update({
          'accepted_terms_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);

        // Borra el flag local si se actualizó exitosamente
        await prefs.remove(_termsPendingKey);
        debugPrint('OnboardingService: Términos sincronizados con éxito en Supabase.');
      }
    } catch (e) {
      debugPrint('OnboardingService: Error sincronizando términos: $e');
    }
  }
}
