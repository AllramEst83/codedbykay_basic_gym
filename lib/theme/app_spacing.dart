/// Spacing tokens (multiples of an 8px base unit) and shape radii
/// for the Kinetic Pastel design language.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double base = 8;
  static const double sm = 12;
  static const double gutter = 16;
  static const double containerMargin = 20;
  static const double md = 24;
  static const double lg = 40;
  static const double xl = 64;
}

/// Border radius tokens. Cards prefer [card], pill-shaped elements use [pill].
class AppRadius {
  AppRadius._();

  static const double sm = 8; // 0.5rem
  static const double md = 16; // 1rem (DEFAULT)
  static const double card = 24; // 1.5rem
  static const double lg = 32; // 2rem
  static const double xl = 48; // 3rem
  static const double pill = 9999;
}
