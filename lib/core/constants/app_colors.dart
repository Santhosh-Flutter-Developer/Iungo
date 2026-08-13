import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary brand purple — AppBar, primary buttons, active toggle.
  static const Color primary = Color(0xFF652E68);
  static const Color primaryDark = Color(0xFF5D2A60);

  /// Screen background (login / forms / dashboard).
  static const Color background = Color(0xFFF4F4F4);
  static const Color scaffoldWhite = Color(0xFFFFFFFF);

  /// Dashboard grid tile background.
  static const Color cardBackground = Color(0xFFFAFAFA);

  /// "New Service Request" form header background (lighter than primary AppBar).
  static const Color formHeaderBackground = Color(0xFFEAEAEC);

  /// Shadow used behind the white "User Location" card.
  static const Color cardShadow = Color(0x1A000000);

  /// Drawer: selected-item highlight and header chrome.
  static const Color drawerSelectedBackground = Color(0xFFEBE6EC);
  static const Color drawerCollapseButtonBackground = Color(0xFF808DA0);
  static const Color divider = Color(0xFFD7D7D7);

  /// Heading / label blue-grey used for "Welcome" and subtitles.
  static const Color headingBlueGrey = Color(0xFF61718A);

  /// Input field styling.
  static const Color inputFill = Color(0xFFFAFAFA);
  static const Color inputBorder = Color(0xFFD7D7D7);
  static const Color inputIcon = Color(0xFF3F4045);

  /// Body text.
  static const Color textDark = Color(0xFF1C1B20);
  static const Color textMuted = Color(0xFF63646B);

  /// Infinity logo gradient (dark maroon top -> bright red bottom).
  static const Color logoGradientTop = Color(0xFF6B0F1A);
  static const Color logoGradientBottom = Color(0xFFE2231A);

  /// Privacy policy link.
  static const Color link = Color(0xFF1565C0);

  /// Error / info snackbar (e.g. "Account not found").
  static const Color snackbarBackground = Color(0xFF2A3C50);
  static const Color snackbarIcon = Color(0xFFE53935);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Detail View — Attachments tab: "View" / "Delete" pill buttons.
  static const Color attachmentViewBackground = Color(0xFFE9E3EA);
  static const Color attachmentDeleteBackground = Color(0xFFF8DCDA);
  static const Color attachmentDeleteText = Color(0xFFB3261E);

  /// Detail View — faint grey used for field labels like "Description",
  /// "Assigned Technician", "Other Information".
  static const Color labelGrey = Color(0xFFB3B3B3);
}
