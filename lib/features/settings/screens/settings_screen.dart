import 'package:flutter/material.dart';
import 'package:stadia/core/services/theme_service.dart';
import 'package:stadia/core/services/size_service.dart';
import 'package:stadia/core/widgets/stadia_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import 'package:stadia/core/theme/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentTheme = ThemeService.themeNotifier.value;

    return ProtectedRoute(
      child: StadiaScaffold(
        title: 'Ajustes',
        body: ValueListenableBuilder<AppSizeScale>(
          valueListenable: SizeService.sizeNotifier,
          builder: (context, currentSize, _) {
            return ListView(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.scaled(context, AppSpacing.md),
                    right: AppSpacing.scaled(context, AppSpacing.md),
                    top: AppSpacing.scaled(context, AppSpacing.lg),
                    bottom: AppSpacing.scaled(context, AppSpacing.sm),
                  ),
                  child: Text(
                    'Estilos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Modo claro'),
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ThemeService.setThemeAndSync(value, onSyncToProfile: (data) {
                        context.read<UserProvider>().updateProfile(data);
                      });
                      setState(() {});
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Modo oscuro'),
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ThemeService.setThemeAndSync(value, onSyncToProfile: (data) {
                        context.read<UserProvider>().updateProfile(data);
                      });
                      setState(() {});
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Similar al sistema'),
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      ThemeService.setThemeAndSync(value, onSyncToProfile: (data) {
                        context.read<UserProvider>().updateProfile(data);
                      });
                      setState(() {});
                    }
                  },
                ),
                SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.scaled(context, AppSpacing.md),
                    right: AppSpacing.scaled(context, AppSpacing.md),
                    top: AppSpacing.scaled(context, AppSpacing.md),
                    bottom: AppSpacing.scaled(context, AppSpacing.sm),
                  ),
                  child: Text(
                    'Tamaño',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Divider(height: 1),
                RadioListTile<AppSizeScale>(
                  title: const Text('Small'),
                  value: AppSizeScale.small,
                  groupValue: currentSize,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (AppSizeScale? value) async {
                    if (value != null) {
                      await SizeService.setSize(value);
                      if (mounted) setState(() {});
                    }
                  },
                ),
                RadioListTile<AppSizeScale>(
                  title: const Text('Mid'),
                  value: AppSizeScale.mid,
                  groupValue: currentSize,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (AppSizeScale? value) async {
                    if (value != null) {
                      await SizeService.setSize(value);
                      if (mounted) setState(() {});
                    }
                  },
                ),
                RadioListTile<AppSizeScale>(
                  title: const Text('Big'),
                  value: AppSizeScale.big,
                  groupValue: currentSize,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (AppSizeScale? value) async {
                    if (value != null) {
                      await SizeService.setSize(value);
                      if (mounted) setState(() {});
                    }
                  },
                ),
                SizedBox(height: AppSpacing.scaled(context, AppSpacing.md)),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.scaled(context, AppSpacing.md),
                    right: AppSpacing.scaled(context, AppSpacing.md),
                    top: AppSpacing.scaled(context, AppSpacing.md),
                    bottom: AppSpacing.scaled(context, AppSpacing.sm),
                  ),
                  child: Text(
                    'Créditos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.scaled(context, AppSpacing.md)),
                  child: Column(
                    children: [
                      const Text(
                        'Ardanny Romero & Brandon Huera',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.scaled(context, AppSpacing.xs)),
                      const Text(
                        'Desarrolladores de software - EPN',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
