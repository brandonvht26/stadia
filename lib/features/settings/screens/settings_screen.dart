import 'package:flutter/material.dart';
import 'package:stadia/core/services/theme_service.dart';
import 'package:stadia/core/services/size_service.dart';
import 'package:stadia/core/widgets/stadia_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';

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
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
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
                  onChanged: (AppSizeScale? value) {
                    if (value != null) {
                      SizeService.setSizeAndSync(value, onSyncToProfile: (data) {
                        context.read<UserProvider>().updateProfile(data);
                      });
                      setState(() {});
                    }
                  },
                ),
                RadioListTile<AppSizeScale>(
                  title: const Text('Mid'),
                  value: AppSizeScale.mid,
                  groupValue: currentSize,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (AppSizeScale? value) {
                    if (value != null) {
                      SizeService.setSizeAndSync(value, onSyncToProfile: (data) {
                        context.read<UserProvider>().updateProfile(data);
                      });
                      setState(() {});
                    }
                  },
                ),
                RadioListTile<AppSizeScale>(
                  title: const Text('Big'),
                  value: AppSizeScale.big,
                  groupValue: currentSize,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onChanged: (AppSizeScale? value) {
                    if (value != null) {
                      SizeService.setSizeAndSync(value, onSyncToProfile: (data) {
                        context.read<UserProvider>().updateProfile(data);
                      });
                      setState(() {});
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
