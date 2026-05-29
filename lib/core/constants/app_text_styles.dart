import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised text styles for the app.
/// Heading/display: Lexend — body/supporting: Plus Jakarta Sans.
/// Change font or scale here and it propagates everywhere.
abstract class AppTextStyles {
  // ── Display / page headings ───────────────────────────────────────────────

  /// Large page/AppBar title (e.g. "My Exams", "Drive Test")
  static TextStyle displayLarge({Color? color}) => GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color,
      );

  /// Standard section heading (e.g. "Exams", username)
  static TextStyle headingLarge({Color? color}) => GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Card / list-item heading
  static TextStyle headingMedium({Color? color}) => GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Small label / badge heading
  static TextStyle headingSmall({Color? color}) => GoogleFonts.lexend(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // ── Body / supporting text ────────────────────────────────────────────────

  /// Primary body text
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Secondary / subtitle text
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.lexend(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Caption / hint text
  static TextStyle bodySmall({Color? color}) => GoogleFonts.lexend(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Menu / list tiles ─────────────────────────────────────────────────────

  /// List tile primary title
  static TextStyle listTitle({Color? color}) => GoogleFonts.lexend(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// List tile subtitle / description
  static TextStyle listSubtitle({Color? color}) => GoogleFonts.lexend(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
