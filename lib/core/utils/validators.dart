class Validators {
  Validators._();

  // Allows the "+" tag character (e.g. dinesh.r+citclient@facilio.com)
  // alongside the usual letters/digits/dots/hyphens in the local part.
  static final RegExp _emailRegex =
      RegExp(r'^[\w.+\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  static bool isNotEmpty(String value) => value.trim().isNotEmpty;
}
