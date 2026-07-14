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
import '../../host/presentation/screens/my_receptions_screen.dart';
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
              ClipOval(
                child: Container(
                  width: 80,
                  height: 80,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3));
                          },
                        )
                      : Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
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
                    child: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (bio.isNotEmpty) ...[
                SizedBox(height: AppSpacing.scaled(context, AppSpacing.sm)),
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),

              // 2. Estadísticas
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ESTADÍSTICAS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              statsProvider.isLoading ? '-' : '${statsProvider.myReceptions.length}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Recepciones', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              statsProvider.isLoading ? '-' : '${statsProvider.reservationsCount}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Reservas', style: Theme.of(context).textTheme.bodySmall),
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
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),

              // 3. Opciones
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OPCIONES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
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
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Ajustes', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BankAccountScreen.route()));
                      },
                      icon: const Icon(Icons.account_balance, size: 16),
                      label: const Text('Banco', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onLogout(context),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Salir', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),

              // 4. Recepciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECEPCIONES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyReceptionsScreen()),
                      ).then((_) => statsProvider.loadStats());
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ver todas', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    MyReceptionsScreen.handleCreateReception(
                      context,
                      () => statsProvider.loadStats(),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear recepción'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (statsProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (statsProvider.myReceptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(Icons.storefront, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('No has creado recepciones', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
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
