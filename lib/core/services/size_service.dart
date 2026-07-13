import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSizeScale { small, mid, big }

class SizeService {
  static final ValueNotifier<AppSizeScale> sizeNotifier = ValueNotifier(AppSizeScale.mid);

  static Future<void> loadSize() async {
    final prefs = await SharedPreferences.getInstance();
    final sizeString = prefs.getString('size_scale');
    
    switch (sizeString) {
      case 'small':
        sizeNotifier.value = AppSizeScale.small;
        break;
      case 'big':
        sizeNotifier.value = AppSizeScale.big;
        break;
      case 'mid':
      default:
        sizeNotifier.value = AppSizeScale.mid;
        break;
    }
  }

  static Future<void> setSize(AppSizeScale scale) async {
    sizeNotifier.value = scale;
    final prefs = await SharedPreferences.getInstance();
    
    String sizeString;
    switch (scale) {
      case AppSizeScale.small:
        sizeString = 'small';
        break;
      case AppSizeScale.big:
        sizeString = 'big';
        break;
      case AppSizeScale.mid:
      default:
        sizeString = 'mid';
        break;
    }
    
    await prefs.setString('size_scale', sizeString);
  }

  static Future<void> setSizeAndSync(
    AppSizeScale scale, {
    Function(Map<String, dynamic>)? onSyncToProfile,
  }) async {
    await setSize(scale);
    if (onSyncToProfile != null) {
      String sizeString;
      switch (scale) {
        case AppSizeScale.small:
          sizeString = 'small';
          break;
        case AppSizeScale.big:
          sizeString = 'big';
          break;
        case AppSizeScale.mid:
        default:
          sizeString = 'mid';
          break;
      }
      onSyncToProfile({'size_preference': sizeString});
    }
  }

  static double get scaleFactor {
    switch (sizeNotifier.value) {
      case AppSizeScale.small:
        return 0.9;
      case AppSizeScale.big:
        return 1.15;
      case AppSizeScale.mid:
      default:
        return 1.0;
    }
  }

  static double get spacingScale {
    switch (sizeNotifier.value) {
      case AppSizeScale.small:
        return 0.75;
      case AppSizeScale.big:
        return 1.25;
      case AppSizeScale.mid:
      default:
        return 1.0;
    }
  }
}
