class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  static bool isNotEmpty(String value) => value.trim().isNotEmpty;
}
