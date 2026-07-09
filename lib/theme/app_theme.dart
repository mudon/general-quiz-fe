import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeckColors {
  DeckColors._();

  static const paper = Color(0xFFEFEDE4);
  static const paperDark = Color(0xFFE4E1D4);
  static const ink = Color(0xFF20232E);
  static const graphite = Color(0xFF5B6270);
  static const graphiteFaint = Color(0xFF9AA0AC);
  static const blue = Color(0xFF2F55D4);
  static const blueFaint = Color(0xFFDCE3FA);
  static const green = Color(0xFF3D7A5C);
  static const greenFaint = Color(0xFFDEEBE3);
  static const red = Color(0xFFB0413E);
  static const redFaint = Color(0xFFF5E1DF);
  static const yellow = Color(0xFFF2C230);
  static const yellowBg = Color(0xFFFFF6DC);
  static const rule = Color(0xFFC9C5B6);
  static const darkBg = Color(0xFF2A2C33);

  // Keep for backward compat with existing references
  static const primary = blue;
  static const primaryLight = blueFaint;
  static const primaryBg = blueFaint;
  static const secondary = yellow;
  static const secondaryLight = yellowBg;
  static const success = green;
  static const successBg = greenFaint;
  static const error = red;
  static const errorBg = redFaint;
  static const gold = yellow;
  static const sky = blue;
  static const pink = red;
  static const lime = Color(0xFFC6FF00);
  static const surface = paper;
  static const textPrimary = ink;
  static const textSecondary = graphite;
  static const outline = ink;

  static const List<Color> bubbleColors = [
    Color(0xFF2F55D4),
    Color(0xFF3D7A5C),
    Color(0xFFB0413E),
    Color(0xFFF2C230),
    Color(0xFF5B6270),
    Color(0xFF9AA0AC),
    Color(0xFF20232E),
    Color(0xFFEFEDE4),
    Color(0xFFE4E1D4),
  ];

  static const List<String> bubbleEmojis = [
    '\u{1F30D}', '\u{1F9EA}', '\u{1F3AC}', '\u{1F4BB}', '\u26BD',
    '\u{1F354}', '\u{1F9EC}', '\u{1F680}', '\u{1F3DB}\uFE0F',
    '\u{1F3B5}', '\u{1F6E1}\uFE0F', '\u{1F3AE}', '\u2615', '\u{1F3C6}',
  ];

  static String emojiForIndex(int i) => bubbleEmojis[i % bubbleEmojis.length];

  static const List<Color> confettiColors = [
    blue,
    green,
    red,
    yellow,
    Color(0xFF5B6270),
    Color(0xFF2F55D4),
    Color(0xFF3D7A5C),
    Color(0xFFB0413E),
    Color(0xFFF2C230),
  ];
}

class DeckTheme {
  DeckTheme._();

  static TextStyle spaceGrotesk({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = DeckColors.ink,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle ibmPlexMono({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w500,
    Color color = DeckColors.graphite,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle literata({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = DeckColors.ink,
    double? height,
  }) {
    return GoogleFonts.literata(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: DeckColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DeckColors.ink,
        brightness: Brightness.light,
        surface: DeckColors.paper,
        onSurface: DeckColors.ink,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: DeckColors.paper,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: DeckColors.paper,
        foregroundColor: DeckColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: DeckTheme.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        shape: const Border(
          bottom: BorderSide(color: DeckColors.ink, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: DeckColors.paper,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DeckTheme.ibmPlexMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: DeckColors.ink,
            );
          }
          return DeckTheme.ibmPlexMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: DeckColors.graphiteFaint,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: DeckColors.rule, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: DeckColors.rule, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: DeckColors.blue, width: 2),
        ),
        filled: true,
        fillColor: DeckColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        backgroundColor: DeckColors.ink,
        contentTextStyle: DeckTheme.ibmPlexMono(
          fontSize: 10,
          color: DeckColors.paper,
        ),
      ),
      cardTheme: CardThemeData(
        color: DeckColors.paperDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }
}
