import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/widgets/stadia_scaffold.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import 'package:stadia/features/profile/screens/personal_data_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../host/presentation/screens/bank_account_screen.dart';
import '../../host/presentation/screens/create_reception_screen.dart';
import '../../host/presentation/screens/manage_photos_screen.dart';
import '../providers/profile_stats_provider.dart';
import 'package:stadia/core/theme/app_spacing.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ProfileStatsProvider();
        Future.microtask(() => provider.loadStats());
        return provider;
      },
      child: const _ProfileTabContent(),
    );
  }
}

class _ProfileTabContent extends StatelessWidget {
  const _ProfileTabContent();

  void _onLogout(BuildContext context) async {
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
        if (context.mounted) {
          context.read<UserProvider>().clear();
        }
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
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final statsProvider = context.watch<ProfileStatsProvider>();
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
    final createdAt = profile['created_at'] as String?;

    return ProtectedRoute(
      child: StadiaScaffold(
        title: 'Perfil',
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.scaled(context, AppSpacing.md),
            vertical: AppSpacing.scaled(context, AppSpacing.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header: Avatar + Nombre + Editar + Teléfono
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (firstName.isEmpty && lastName.isEmpty)
                        ? 'Usuario Stadia'
                        : '$firstName $lastName'.trim(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
                      );
                    },
                    child: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              if (bio.isNotEmpty) ...[
                SizedBox(height: AppSpacing.scaled(context, AppSpacing.sm)),
                Text(
                  bio,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),

              // 2. Estadísticas
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ESTADÍSTICAS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              statsProvider.isLoading ? '-' : '${statsProvider.myReceptions.length}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Recepciones', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              statsProvider.isLoading ? '-' : '${statsProvider.reservationsCount}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Reservas', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                statsProvider.getMemberSinceFormatted(createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),

              // 3. Opciones
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OPCIONES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                      icon: const Icon(Icons.settings, size: 16, color: Colors.black87),
                      label: const Text('Ajustes', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BankAccountScreen.route()));
                      },
                      icon: const Icon(Icons.account_balance, size: 16, color: Colors.black87),
                      label: const Text('Banco', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onLogout(context),
                      icon: const Icon(Icons.logout, size: 16, color: Colors.red),
                      label: const Text('Salir', style: TextStyle(fontSize: 12, color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),

              // 4. Recepciones
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RECEPCIONES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 8),
              if (statsProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (statsProvider.myReceptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(Icons.storefront, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No has creado recepciones', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateReceptionScreen()),
                          ).then((_) => statsProvider.loadStats());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Crear recepción'),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                  itemCount: statsProvider.myReceptions.length,
                  itemBuilder: (context, index) {
                    final reception = statsProvider.myReceptions[index];
                    final imageUrl = reception.imageUrls.isNotEmpty ? reception.imageUrls.first : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ManagePhotosScreen.route(receptionId: reception.id)),
                        ).then((_) => statsProvider.loadStats());
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null)
                            Image.network(imageUrl, fit: BoxFit.cover)
                          else
                            Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.photo, color: Colors.grey),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_border, color: Colors.white, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${reception.likesCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
