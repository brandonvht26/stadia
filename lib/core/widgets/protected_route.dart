import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/features/auth/screens/login_screen.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession == null) {
      return const LoginScreen();
    }
    return child;
  }
}
