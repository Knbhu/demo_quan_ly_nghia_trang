import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/mausala.dart';
import 'screens/trangchukhachvanglai.dart';

void main() => runApp(const SalaGardenApp());

class SalaGardenApp extends StatelessWidget {
  const SalaGardenApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sala Garden', debugShowCheckedModeBanner: false,
  theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: MauSala.xanhThe), scaffoldBackgroundColor: MauSala.nen, useMaterial3: true, textTheme: GoogleFonts.manropeTextTheme(), fontFamily: GoogleFonts.manrope().fontFamily),
  home: const TrangChuKhachVangLai(),
  );
}
