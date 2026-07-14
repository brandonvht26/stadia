import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import 'package:stadia/features/profile/screens/personal_data_screen.dart';
import '../../onboarding/presentation/widgets/onboarding_background.dart';
import '../../settings/screens/settings_screen.dart';
import '../../host/presentation/screens/bank_account_screen.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    if (userProvider.isLoading || profile == null) {
      return const ProtectedRoute(
        child: OnboardingBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: null,
            body: Center(
              child: CircularProgressIndicator(),
            ),
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
      child: OnboardingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.scaled(context, AppSpacing.md),
              right: AppSpacing.scaled(context, AppSpacing.md),
              top: AppSpacing.scaled(context, AppSpacing.lg),
              bottom: AppSpacing.scaled(context, AppSpacing.lg) + MediaQuery.of(context).padding.bottom + 24, // Clearance for navigation bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Header: Avatar + Nombre + Editar + Teléfono
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.5),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                        shape: BoxShape.circle,
                      ),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 50, color: colorScheme.onSurface.withOpacity(0.5));
                              },
                            )
                          : Icon(Icons.person, size: 50, color: colorScheme.onSurface.withOpacity(0.5)),
                    ),
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
                        fontSize: 24,
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
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, size: 16, color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                if (bio.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.scaled(context, AppSpacing.sm)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    child: Text(
                      bio,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                colorScheme.primary.withOpacity(0.05),
                                colorScheme.surface.withOpacity(0.8),
                              ),
                              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                colorScheme.primary.withOpacity(0.05),
                                colorScheme.surface.withOpacity(0.8),
                              ),
                              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  statsProvider.getMemberSinceFormatted(createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6)
                  ),
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
                      child: _GlassButton(
                        icon: Icons.settings,
                        label: 'Ajustes',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GlassButton(
                        icon: Icons.account_balance,
                        label: 'Banco',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => BankAccountScreen.route()));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GlassButton(
                        icon: Icons.logout,
                        label: 'Salir',
                        color: Colors.red,
                        onTap: () => _onLogout(context),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            MyReceptionsScreen.handleCreateReception(
                              context,
                              () => statsProvider.loadStats(),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20, color: colorScheme.onPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  'Crear recepción',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (imageUrl != null)
                                Image.network(imageUrl, fit: BoxFit.cover)
                              else
                                Container(
                                  color: colorScheme.surface.withOpacity(0.5),
                                  child: const Icon(Icons.photo, color: Colors.grey),
                                ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.favorite, color: Colors.white, size: 10),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${reception.likesCount}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemColor = color ?? colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: colorScheme.surface.withOpacity(0.6),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: itemColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 20, color: itemColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: itemColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

