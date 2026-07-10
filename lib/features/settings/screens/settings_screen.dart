import 'package:flutter/material.dart';
import 'package:stadia/core/services/theme_service.dart';
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
        body: ListView(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
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
              title: const Text('Oscuro'),
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
              title: const Text('Sistema'),
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
          ],
        ),
      ),
    );
  }
}
