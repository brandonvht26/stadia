import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/core/widgets/stadia_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import 'package:stadia/core/providers/user_provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Desconocido';
    return ProtectedRoute(
      child: StadiaScaffold(
        title: 'Lobby',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<UserProvider>().clear();
              Supabase.instance.client.auth.signOut();
            },
          ),
        ],
        body: Center(
          child: Text(
            'Usuario ingresó exitosamente\n$userEmail',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
