import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:stadia/core/services/theme_service.dart';
import 'package:stadia/core/services/size_service.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import 'package:stadia/core/theme/app_spacing.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentTheme = ThemeService.themeNotifier.value;
    final colorScheme = Theme.of(context).colorScheme;

    return ProtectedRoute(
      child: OnboardingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ValueListenableBuilder<AppSizeScale>(
            valueListenable: SizeService.sizeNotifier,
            builder: (context, currentSize, _) {
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.scaled(context, AppSpacing.md),
                  vertical: AppSpacing.scaled(context, AppSpacing.sm),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.scaled(context, AppSpacing.sm),
                      right: AppSpacing.scaled(context, AppSpacing.sm),
                      top: AppSpacing.scaled(context, AppSpacing.md),
                      bottom: AppSpacing.scaled(context, AppSpacing.sm),
                    ),
                    child: Text(
                      'Estilos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  _buildGlassContainer(
                    context,
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: const Text('Modo claro'),
                          value: ThemeMode.light,
                          groupValue: currentTheme,
                          activeColor: colorScheme.primary,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              ThemeService.setThemeAndSync(value, onSyncToProfile: (data) {
                                context.read<UserProvider>().updateProfile(data);
                              });
                              setState(() {});
                            }
                          },
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                        RadioListTile<ThemeMode>(
                          title: const Text('Modo oscuro'),
                          value: ThemeMode.dark,
                          groupValue: currentTheme,
                          activeColor: colorScheme.primary,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              ThemeService.setThemeAndSync(value, onSyncToProfile: (data) {
                                context.read<UserProvider>().updateProfile(data);
                              });
                              setState(() {});
                            }
                          },
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                        RadioListTile<ThemeMode>(
                          title: const Text('Similar al sistema'),
                          value: ThemeMode.system,
                          groupValue: currentTheme,
                          activeColor: colorScheme.primary,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              ThemeService.setThemeAndSync(value, onSyncToProfile: (data) {
                                context.read<UserProvider>().updateProfile(data);
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.scaled(context, AppSpacing.sm),
                      right: AppSpacing.scaled(context, AppSpacing.sm),
                      top: AppSpacing.scaled(context, AppSpacing.md),
                      bottom: AppSpacing.scaled(context, AppSpacing.sm),
                    ),
                    child: Text(
                      'Tamaño',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  _buildGlassContainer(
                    context,
                    child: Column(
                      children: [
                        RadioListTile<AppSizeScale>(
                          title: const Text('Pequeño (Small)'),
                          value: AppSizeScale.small,
                          groupValue: currentSize,
                          activeColor: colorScheme.primary,
                          onChanged: (AppSizeScale? value) async {
                            if (value != null) {
                              await SizeService.setSize(value);
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                        RadioListTile<AppSizeScale>(
                          title: const Text('Mediano (Mid)'),
                          value: AppSizeScale.mid,
                          groupValue: currentSize,
                          activeColor: colorScheme.primary,
                          onChanged: (AppSizeScale? value) async {
                            if (value != null) {
                              await SizeService.setSize(value);
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                        RadioListTile<AppSizeScale>(
                          title: const Text('Grande (Big)'),
                          value: AppSizeScale.big,
                          groupValue: currentSize,
                          activeColor: colorScheme.primary,
                          onChanged: (AppSizeScale? value) async {
                            if (value != null) {
                              await SizeService.setSize(value);
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.scaled(context, AppSpacing.sm),
                      right: AppSpacing.scaled(context, AppSpacing.sm),
                      top: AppSpacing.scaled(context, AppSpacing.md),
                      bottom: AppSpacing.scaled(context, AppSpacing.sm),
                    ),
                    child: Text(
                      'Créditos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  _buildGlassContainer(
                    context,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.scaled(context, AppSpacing.md)),
                      child: Column(
                        children: [
                          const Text(
                            'Ardanny Romero & Brandon Huera',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.scaled(context, AppSpacing.xs)),
                          Text(
                            'Desarrolladores de software - EPN',
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.scaled(context, AppSpacing.xl)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface.withOpacity(0.7),
            ),
            border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}
