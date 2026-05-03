import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const terracota     = Color(0xFFC45E3E);
const bege          = Color(0xFFF5EFE6);
const offWhite      = Color(0xFFFAFAFA);
const verdeMsgo     = Color(0xFF4A7C59);
const vermelhoSuave = Color(0xFFD64040);
const amareloAlerta = Color(0xFFE8A020);
const cinzaTexto    = Color(0xFF4A4A4A);
const cinzaMuted    = Color(0xFF9E9E9E);

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: terracota,
      primary:   terracota,
      surface:   offWhite,
    ),
    scaffoldBackgroundColor: offWhite,
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      bodyMedium:   GoogleFonts.nunitoSans(color: cinzaTexto),
      bodySmall:    GoogleFonts.nunitoSans(color: cinzaMuted),
      titleLarge:   GoogleFonts.nunito(fontWeight: FontWeight.bold),
      titleMedium:  GoogleFonts.nunito(fontWeight: FontWeight.w600),
      labelMedium:  GoogleFonts.nunito(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: terracota,
      foregroundColor: Colors.white,
      elevation:       0,
      centerTitle:     true,
      titleTextStyle:  GoogleFonts.nunito(
        color:      Colors.white,
        fontSize:   18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: terracota,
        foregroundColor: Colors.white,
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding:         const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border:          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder:   OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: terracota, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color:     Colors.white,
      elevation: 0,
      shape:     RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:         BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    useMaterial3: true,
  );
}
