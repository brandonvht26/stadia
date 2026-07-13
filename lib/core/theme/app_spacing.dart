import 'package:flutter/material.dart';
import '../services/size_service.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static double scaled(BuildContext context, double base) {
    return base * SizeService.spacingScale;
  }
}
