/// Small hand-rolled date formatters — the project has no `intl`
/// dependency, and the reference design only ever needs these two shapes.
class AppDateFormat {
  AppDateFormat._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Jul 9, 2026" — used for the attachment list and generic dates.
  static String mediumDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// "Jul 9, 2026 (19:11PM)" — matches the reference screenshot's raw
  /// 24-hour clock value with an AM/PM suffix appended, kept as-is
  /// (quirk and all) to match the design exactly.
  static String mediumDateWithTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${mediumDate(date)} ($hh:$mm$suffix)';
  }
}
