import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/core/widgets/stadia_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import 'package:stadia/features/profile/screens/personal_data_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../host/presentation/screens/bank_account_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;

    if (userProvider.isLoading || profile == null) {
      return const ProtectedRoute(
        child: StadiaScaffold(
          title: 'Perfil',
          body: Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
        ),
      );
    }

    final avatarUrl = profile['avatar_url'] as String?;
    final firstName = profile['first_name'] as String? ?? '';
    final lastName = profile['last_name'] as String? ?? '';
    final phone = profile['phone'] as String? ?? '';
    final bio = profile['bio'] as String? ?? '';

    return ProtectedRoute(
      child: StadiaScaffold(
        title: 'Perfil',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Foto de perfil (solo visual)
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              
              // 2. Datos del usuario (solo visual)
              Text(
                (firstName.isEmpty && lastName.isEmpty)
                    ? 'Usuario Stadia'
                    : '$firstName $lastName'.trim(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              const SizedBox(height: 16),
              if (bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // 3. Subtítulo "Opciones" con divisor
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Opciones',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Divider(height: 16),
              const SizedBox(height: 16),
              
              // 4. Botón Ajustes
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Colors.black),
                  label: const Text('Ajustes', style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 5. Botón Datos Personales
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
                    );
                  },
                  icon: const Icon(Icons.badge, color: Colors.black),
                  label: const Text('Datos Personales', style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 6. Botón Datos Bancarios
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BankAccountScreen.route()),
                    );
                  },
                  icon: const Icon(Icons.account_balance, color: Colors.black),
                  label: const Text('Datos Bancarios', style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 7. Botón Cerrar Sesión
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Seguro que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await Supabase.instance.client.auth.signOut();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al cerrar sesión'),
                              backgroundColor: Colors.black87,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
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
