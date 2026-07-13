import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/features/auth/screens/login_screen.dart';
import 'package:stadia/features/lobby/screens/lobby_screen.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/services/onboarding_service.dart';
import 'package:stadia/features/onboarding/presentation/screens/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService.hasSeenOnboarding(),
      builder: (context, onboardingSnapshot) {
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        final hasSeenOnboarding = onboardingSnapshot.data ?? false;

        if (!hasSeenOnboarding) {
          return const WelcomeScreen();
        }

        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }

            final session = snapshot.data?.session;
            if (session != null) {
              final userProvider = context.read<UserProvider>();
              final currentProfileId = userProvider.profile?['id'] as String?;
              final sessionUserId = session.user.id;
              
              if ((userProvider.profile == null || currentProfileId != sessionUserId) 
                  && !userProvider.isLoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  userProvider.loadProfile();
                });
              }
              return const LobbyScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
