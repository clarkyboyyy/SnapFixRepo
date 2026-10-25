import 'package:flutter/material.dart';

/// SnapFix palette: white / light-grey surfaces, charcoal text and a pastel
/// magenta accent.
class AppTheme {
  AppTheme._();

  static const Color pink = Color(0xFFEC2D6E);
  static const Color deepPink = Color(0xFFC2185B);
  static const Color softPink = Color(0xFFFDE7EF);
  static const Color charcoal = Color(0xFF2B2B33);
  static const Color muted = Color(0xFF8A8A94);
  static const Color border = Color(0xFFEDEDF2);
  static const Color surface = Color(0xFFFAFAFC);

  static const Color submitted = pink;
  static const Color inProgress = Color(0xFFFF9C27);
  static const Color resolved = Color(0xFF27945B);

  /// Pink wash drawn under any widget the pointer is resting on.
  static const Color _hover = Color(0x14EC2D6E);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink,
        primary: pink,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: surface,
      hoverColor: _hover,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: charcoal,
        displayColor: charcoal,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _fieldBorder,
        enabledBorder: _fieldBorder,
        focusedBorder: _fieldBorder.copyWith(
          borderSide: const BorderSide(color: pink, width: 1.4),
        ),
        errorBorder: _fieldBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFD93B3B)),
        ),
        focusedErrorBorder: _fieldBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFD93B3B), width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          overlayColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pink,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          overlayColor: pink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: pink, overlayColor: pink),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(overlayColor: pink),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: charcoal,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: softPink,
        height: 66,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? _hover : null,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: charcoal,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  static const OutlineInputBorder _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: border),
  );

  /// Colour used for a report status pill.
  static Color statusColor(String status) => switch (status) {
    'Resolved' => resolved,
    'In Progress' => inProgress,
    _ => submitted,
  };
}
