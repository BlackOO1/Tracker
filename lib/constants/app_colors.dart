import 'package:flutter/material.dart';

/// Color palette extracted exactly from Expense Tracker.xlsx theme
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF1C1F31);   // Main dark navy
  static const Color surface    = Color(0xFF282C40);   // Card surface
  static const Color divider    = Color(0xFF3D425D);   // Borders/dividers
  static const Color surfaceAlt = Color(0xFF2E3348);   // Slightly lighter surface

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD0D6E0);
  static const Color textMuted     = Color(0xFF8892A4);

  // Accent palette (from xl/theme/theme1.xml)
  static const Color teal    = Color(0xFF5DD8D0);  // accent1
  static const Color pink    = Color(0xFFECB0CC);  // accent2
  static const Color lavender= Color(0xFFB3ACFA);  // accent3
  static const Color peach   = Color(0xFFF79F8F);  // accent4
  static const Color yellow  = Color(0xFFFDE288);  // accent5
  static const Color mint    = Color(0xFFC6F1B2);  // accent6

  // Semantic
  static const Color income   = teal;
  static const Color expense  = peach;
  static const Color bill     = yellow;
  static const Color debt     = pink;
  static const Color savings  = mint;
  static const Color chart1   = teal;
  static const Color chart2   = pink;
  static const Color chart3   = lavender;
  static const Color chart4   = peach;
  static const Color chart5   = yellow;
  static const Color chart6   = mint;

  static const List<Color> chartPalette = [teal, pink, lavender, peach, yellow, mint];
}

/// Currency definitions
class Currencies {
  static const Map<String, Map<String, dynamic>> all = {
    'USD': {'symbol': '\$',   'name': 'US Dollar',     'rate': 1.0},
    'INR': {'symbol': '₹',   'name': 'Indian Rupee',   'rate': 83.5},
    'EUR': {'symbol': '€',   'name': 'Euro',           'rate': 0.92},
    'GBP': {'symbol': '£',   'name': 'British Pound',  'rate': 0.79},
    'JPY': {'symbol': '¥',   'name': 'Japanese Yen',   'rate': 149.5},
    'PHP': {'symbol': '₱',   'name': 'Philippine Peso','rate': 56.2},
    'AED': {'symbol': 'AED ','name': 'UAE Dirham',     'rate': 3.67},
    'CAD': {'symbol': 'CA\$','name': 'Canadian Dollar', 'rate': 1.36},
    'AUD': {'symbol': 'A\$', 'name': 'Australian Dollar','rate': 1.53},
    'SGD': {'symbol': 'S\$', 'name': 'Singapore Dollar','rate': 1.34},
  };

  static double rate(String code) => (all[code]?['rate'] as double?) ?? 1.0;
  static String symbol(String code) => (all[code]?['symbol'] as String?) ?? '\$';

  static String format(double usdAmount, String code, {bool showDecimals = true}) {
    final v = usdAmount * rate(code);
    final sym = symbol(code);
    if (code == 'JPY') return '$sym${v.round()}';
    return showDecimals
        ? '$sym${v.toStringAsFixed(2)}'
        : '$sym${v.toStringAsFixed(0)}';
  }
}
