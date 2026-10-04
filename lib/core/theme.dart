import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens (DESIGN-binance.md) ─────────────────────────────────────────
class AppColors {
  AppColors._();

  static const primary          = Color(0xFFFCD535);
  static const primaryActive    = Color(0xFFF0B90B);
  static const primaryDisabled  = Color(0xFF3A3A1F);
  static const ink              = Color(0xFF181A20);
  static const body             = Color(0xFFEAECEF);
  static const muted            = Color(0xFF707A8A);
  static const mutedStrong      = Color(0xFF929AA5);
  static const hairlineDark     = Color(0xFF2B3139);
  static const canvasDark       = Color(0xFF0B0E11);
  static const surfaceCard      = Color(0xFF1E2329);
  static const surfaceElevated  = Color(0xFF2B3139);
  static const onPrimary        = Color(0xFF181A20);
  static const onDark           = Color(0xFFFFFFFF);
  static const tradingUp        = Color(0xFF0ECB81);
  static const tradingDown      = Color(0xFFF6465D);
  static const accentBlue       = Color(0xFF3B82F6);
  static const accentTurquoise  = Color(0xFF2DBDB6);
  static const accentPurple     = Color(0xFF8B5CF6);
  static const accentOrange     = Color(0xFFF59E0B);
  static const accentGray       = Color(0xFF6B7280);
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvasDark,
      colorScheme: const ColorScheme.dark(
        primary:    AppColors.primary,
        onPrimary:  AppColors.onPrimary,
        surface:    AppColors.surfaceCard,
        onSurface:  AppColors.onDark,
        secondary:  AppColors.tradingUp,
        error:      AppColors.tradingDown,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyMedium:    GoogleFonts.inter(color: AppColors.body,   fontSize: 14),
        bodySmall:     GoogleFonts.inter(color: AppColors.muted,  fontSize: 13),
        titleLarge:    GoogleFonts.inter(color: AppColors.onDark, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium:   GoogleFonts.inter(color: AppColors.onDark, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall:    GoogleFonts.inter(color: AppColors.onDark, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall:    GoogleFonts.inter(color: AppColors.muted,  fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:     AppColors.canvasDark,
        elevation:           0,
        scrolledUnderElevation: 0,
        centerTitle:         false,
        iconTheme:           const IconThemeData(color: AppColors.onDark),
        titleTextStyle:      GoogleFonts.inter(
          color: AppColors.onDark, fontSize: 20, fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:   AppColors.surfaceCard,
        indicatorColor:    AppColors.surfaceElevated,
        height:            64,
        labelTextStyle:    WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(color: AppColors.muted, fontSize: 11);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:           true,
        fillColor:        AppColors.surfaceElevated,
        labelStyle:       GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
        hintStyle:        GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
        enabledBorder:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.hairlineDark),
        ),
        focusedBorder:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:   const BorderSide(color: AppColors.tradingDown),
        ),
        contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  AppColors.primary,
          foregroundColor:  AppColors.onPrimary,
          minimumSize:      const Size.fromHeight(48),
          shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation:        0,
          textStyle:        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardTheme(
        color:     AppColors.surfaceCard,
        elevation: 0,
        margin:    EdgeInsets.zero,
        shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerColor:    AppColors.hairlineDark,
      dividerTheme:    const DividerThemeData(color: AppColors.hairlineDark, thickness: 1, space: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:   AppColors.surfaceElevated,
        contentTextStyle:  GoogleFonts.inter(color: AppColors.body),
        shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior:          SnackBarBehavior.floating,
        insetPadding:      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:    AppColors.surfaceCard,
        modalBackgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(color: AppColors.onDark, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.inter(color: AppColors.body, fontSize: 14),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceElevated),
        ),
      ),
    );
  }
}

// ─── Text Style Helpers ───────────────────────────────────────────────────────
class AppText {
  AppText._();

  // Display sizes (Inter)
  static TextStyle displayLg({Color? color}) => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w700, color: color ?? AppColors.onDark, height: 1.1,
  );

  static TextStyle displayMd({Color? color}) => GoogleFonts.inter(
    fontSize: 24, fontWeight: FontWeight.w700, color: color ?? AppColors.onDark, height: 1.2,
  );

  static TextStyle titleLg({Color? color}) => GoogleFonts.inter(
    fontSize: 20, fontWeight: FontWeight.w700, color: color ?? AppColors.onDark,
  );

  static TextStyle titleMd({Color? color}) => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, color: color ?? AppColors.onDark,
  );

  static TextStyle titleMedium({Color? color}) => titleMd(color: color);

  static TextStyle titleSm({Color? color}) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.onDark,
  );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: color ?? AppColors.body,
  );

  static TextStyle bodySm({Color? color}) => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400, color: color ?? AppColors.muted,
  );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500, color: color ?? AppColors.muted,
  );

  static TextStyle button({Color? color}) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w700, color: color ?? AppColors.onPrimary,
  );

  // Number sizes (JetBrains Mono — for financial data)
  static TextStyle numDisplay({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 32, fontWeight: FontWeight.w700, color: color ?? AppColors.onDark, height: 1.1,
  );

  static TextStyle numLg({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 20, fontWeight: FontWeight.w700, color: color ?? AppColors.onDark,
  );

  static TextStyle numMd({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 16, fontWeight: FontWeight.w500, color: color ?? AppColors.body,
  );

  static TextStyle numSm({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w500, color: color ?? AppColors.muted,
  );
}

