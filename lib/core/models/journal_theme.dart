import 'package:flutter/material.dart';

/// A visual theme variant for Portion.
///
/// Each variant bundles a background image, card texture, accent colour, and
/// the dark fallback colour shown on iOS when the user over-scrolls past the
/// top or bottom edge of the screen.
///
/// Add future variants by appending enum entries and supplying matching assets
/// in assets/images/. Register new assets in pubspec.yaml before use.
enum JournalTheme {
  warmDesk(
    id: 'warm_desk',
    displayName: 'Warm Desk',
    bgAsset: 'assets/images/desk_texture.jpg',
    cardBgAsset: 'assets/images/aramaic2.jpg',
    cardOpacity: 0.15,
    accentColor: Color(0xFF5C6B4A),
    scaffoldFallbackColor: Color(0xFF3F2E1F),
  ),
  pastelLight(
    id: 'pastel_light',
    displayName: 'Pastel Light',
    bgAsset: 'assets/images/pastel1.jpg',
    cardBgAsset: 'assets/images/aramaic2.jpg',
    cardOpacity: 0.15,
    accentColor: Color(0xFF4A5A6B),
    scaffoldFallbackColor: Color(0xFF3F2E1F),
  ),
  pastelDark(
    id: 'pastel_dark',
    displayName: 'Pastel Dark',
    bgAsset: 'assets/images/pastel2.jpg',
    cardBgAsset: 'assets/images/aramaic2.jpg',
    cardOpacity: 0.15,
    accentColor: Color(0xFF4A5A6B),
    scaffoldFallbackColor: Color(0xFF2A2A3A),
  );

  // ── Future variants ────────────────────────────────────────────────────────
  // Add entries here when assets are ready, e.g.:
  //
  // pastel(
  //   id: 'pastel',
  //   displayName: 'Pastel',
  //   bgAsset: 'assets/images/bg_pastel.jpg',
  //   cardBgAsset: 'assets/images/card_pastel.jpg',
  //   cardOpacity: 0.12,
  //   accentColor: Color(0xFF7A9E7E),
  //   scaffoldFallbackColor: Color(0xFF3A4A3A),
  // ),

  const JournalTheme({
    required this.id,
    required this.displayName,
    required this.bgAsset,
    required this.cardBgAsset,
    required this.cardOpacity,
    required this.accentColor,
    required this.scaffoldFallbackColor,
  });

  final String id;
  final String displayName;
  final String bgAsset;
  final String cardBgAsset;
  final double cardOpacity;
  final Color accentColor;

  /// Dark solid colour shown on iOS over-scroll edges and as the Scaffold
  /// background behind the scrollable content.
  final Color scaffoldFallbackColor;

  static JournalTheme fromId(String id) => JournalTheme.values.firstWhere(
    (t) => t.id == id,
    orElse: () => JournalTheme.warmDesk,
  );
}
