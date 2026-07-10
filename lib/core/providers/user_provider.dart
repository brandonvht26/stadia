import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/core/services/theme_service.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? profile;
  bool isLoading = false;

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userId = user.id;
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        profile = data;

        final themePref = profile!['theme_preference'];
        if (themePref != null) {
          ThemeMode mode;
          switch (themePref) {
            case 'light':
              mode = ThemeMode.light;
              break;
            case 'dark':
              mode = ThemeMode.dark;
              break;
            case 'system':
            default:
              mode = ThemeMode.system;
              break;
          }
          ThemeService.setTheme(mode);
        }
      }
    } catch (e) {
      // Ignorar error por ahora o manejarlo
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      if (profile != null) {
        profile = {...profile!, ...updates};
      } else {
        profile = updates;
      }
      notifyListeners();
    }
  }

  void updateAvatarUrl(String url) {
    if (profile != null) {
      profile!['avatar_url'] = url;
      notifyListeners();
    }
  }

  void clear() {
    profile = null;
    notifyListeners();
  }
}
