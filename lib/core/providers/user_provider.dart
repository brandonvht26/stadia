import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/core/services/theme_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider() {
    _initRealtime();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _initRealtime();
      } else if (data.event == AuthChangeEvent.signedOut) {
        if (_profileChannel != null) {
          Supabase.instance.client.removeChannel(_profileChannel!);
          _profileChannel = null;
        }
        clear();
      }
    });
  }

  RealtimeChannel? _profileChannel;

  void _initRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final suffix = currentUserId;

    if (_profileChannel != null) {
      Supabase.instance.client.removeChannel(_profileChannel!);
    }

    _profileChannel = Supabase.instance.client.channel('profile-live-$suffix');
    _profileChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: currentUserId,
      ),
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (profile != null) {
          profile = {...profile!, ...newRecord};
          
          // Apply theme preference if changed
          final themePref = newRecord['theme_preference'];
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
          
          notifyListeners();
        }
      },
    ).subscribe();
  }

  Map<String, dynamic>? profile;
  bool isLoading = false;

  Future<void> loadProfile({int retryCount = 0}) async {
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
            .maybeSingle();

        if (data == null && retryCount < 3) {
          isLoading = false;
          await Future.delayed(Duration(milliseconds: 800 * (retryCount + 1)));
          return loadProfile(retryCount: retryCount + 1);
        }

        profile = data;

        if (profile != null) {
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
      }
    } catch (e) {
      debugPrint('Error al cargar perfil (intento $retryCount): $e');
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

  @override
  void dispose() {
    if (_profileChannel != null) {
      Supabase.instance.client.removeChannel(_profileChannel!);
    }
    super.dispose();
  }
}
