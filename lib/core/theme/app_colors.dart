import 'package:flutter/material.dart';

/// Semantic color palette. UI code should reference these constants instead
/// of hardcoding colors, so the palette can be re-themed from one file.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5B67F1); // premium indigo
  static const Color primaryDark = Color(0xFF7A85FF);

  // Semantic financial colors (per spec)
  static const Color income = Color(0xFF2ECC71); // green
  static const Color expense = Color(0xFFE74C3C); // red
  static const Color savings = Color(0xFF3498DB); // blue

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFF7F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1B1D28);
  static const Color textSecondaryLight = Color(0xFF6E7180);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF121218);
  static const Color surfaceDark = Color(0xFF1C1E28);
  static const Color textPrimaryDark = Color(0xFFF2F2F7);
  static const Color textSecondaryDark = Color(0xFFA0A3B1);

  // Utility
  static const Color divider = Color(0xFFE3E5EE);
  static const Color dividerDark = Color(0xFF2C2E3A);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  /// Consistent category color mapping so charts and list icons match.
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF7043),
    'Travel': Color(0xFF29B6F6),
    'Petrol': Color(0xFF8D6E63),
    'Rent': Color(0xFF7E57C2),
    'Electricity Bill': Color(0xFFFFCA28),
    'Water Bill': Color(0xFF26C6DA),
    'Internet': Color(0xFF42A5F5),
    'Mobile Recharge': Color(0xFF66BB6A),
    'Shopping': Color(0xFFEC407A),
    'Entertainment': Color(0xFFAB47BC),
    'Medical': Color(0xFFEF5350),
    'Education': Color(0xFF5C6BC0),
    'Insurance': Color(0xFF26A69A),
    'Household': Color(0xFF8D6E63),
    'Subscription': Color(0xFFFFA726),
    'Maintenance': Color(0xFF78909C),
    'Others': Color(0xFF9E9E9E),
  };

  static Color colorForCategory(String category) =>
      categoryColors[category] ?? categoryColors['Others']!;
}
