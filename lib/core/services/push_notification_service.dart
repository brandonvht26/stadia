import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Para scaffoldMessengerKey

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isListeningForeground = false;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) return;

    // a. Solicitar permisos
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('PushNotificationService - AuthorizationStatus: ${settings.authorizationStatus}');

    // b. Obtener token inicial
    final token = await messaging.getToken();
    debugPrint('PushNotificationService - FCM Token inicial: $token');

    if (token != null) {
      await _saveToken(currentUser.id, token);
    }

    // d. Escuchar cambios de token
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('PushNotificationService - FCM Token renovado: $newToken');
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _saveToken(user.id, newToken);
      }
    });
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
        },
        onConflict: 'fcm_token',
      );
      debugPrint('PushNotificationService - Token guardado exitosamente');
    } catch (e) {
      debugPrint('PushNotificationService - Error al guardar token: $e');
    }
  }

  void listenToForegroundMessages() {
    if (_isListeningForeground) return;
    _isListeningForeground = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('PushNotificationService - Mensaje recibido en foreground: ${message.messageId}');
      
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (body.isNotEmpty) Text(body),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              onPressed: () {
                scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }
}
