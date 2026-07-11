import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/core/auth_gate.dart';
import 'package:stadia/core/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:stadia/features/discovery/data/repositories/discovery_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hbsraxrbdfddakfgfvjc.supabase.co',
    anonKey: 'sb_publishable_bnET93B_eqY-mRbLHVAbEA_rCh0s50z',
  );
  await ThemeService.loadTheme();
  runApp(const StadiaApp());
}

final supabase = Supabase.instance.client;

class StadiaApp extends StatelessWidget {
  const StadiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<DiscoveryProvider>(create: (_) => DiscoveryProvider(DiscoveryRepositoryImpl())),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.themeNotifier,
        builder: (context, currentMode, _) {
          return MaterialApp(
            title: 'Stadia',
            debugShowCheckedModeBanner: false,
            themeMode: currentMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.black,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              fontFamily: 'Roboto',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.white,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              fontFamily: 'Roboto',
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
