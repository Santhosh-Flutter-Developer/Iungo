import 'package:get/get.dart';

/// Small hand-rolled date formatters — the project has no `intl`
/// dependency, and the reference design only ever needs these two shapes.
///
/// Every formatter in this class displays in **Riyadh time (AST,
/// UTC+3)**, regardless of the device's own timezone or the IST
/// timestamps the backend sends. This is the single place all
/// created/due/uploaded/comment dates across the app are formatted
/// (Inventory Request, Service Request, Work Order and Notification all
/// route through here), so converting here is enough to make every
/// screen consistent — see [toRiyadh].
class AppDateFormat {
  AppDateFormat._();

  /// Saudi Arabia does not observe daylight saving time, so Asia/Riyadh
  /// stays a fixed UTC+3 all year round — safe to hard-code without
  /// pulling in the `timezone`/`intl` packages.
  static const Duration _riyadhOffset = Duration(hours: 3);

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

  /// Converts any absolute instant — a UTC epoch, a device-local
  /// `DateTime` (e.g. `DateTime.now()`), or an IST wall-clock value from
  /// the backend — into its Riyadh (AST, UTC+3) wall-clock reading.
  ///
  /// `date.toUtc()` first resolves the *true* instant regardless of how
  /// the value happens to be tagged (local vs. already-UTC), then a
  /// fixed +3h gets Riyadh's clock reading from that instant. This is
  /// exposed publicly so call sites that need Riyadh "today" for
  /// same-day comparisons (e.g. an overdue check) can reuse it instead
  /// of comparing against the device's own `DateTime.now()`.
  static DateTime toRiyadh(DateTime date) => date.toUtc().add(_riyadhOffset);

  /// "Jul 9, 2026" — used for the attachment list and generic dates.
  /// Renders in Riyadh time; see [toRiyadh].
  static String mediumDate(DateTime date) {
    final riyadh = toRiyadh(date);
    return '${_months[riyadh.month - 1]} ${riyadh.day}, ${riyadh.year}';
  }

  /// "Jul 9, 2026 (19:11PM)" — matches the reference screenshot's raw
  /// 24-hour clock value with an AM/PM suffix appended, kept as-is
  /// (quirk and all) to match the design exactly. Renders in Riyadh
  /// time; see [toRiyadh].
  static String mediumDateWithTime(DateTime date) {
    final riyadh = toRiyadh(date);
    final hh = riyadh.hour.toString().padLeft(2, '0');
    final mm = riyadh.minute.toString().padLeft(2, '0');
    final suffix = riyadh.hour >= 12 ? 'PM' : 'AM';
    return '${mediumDate(date)} ($hh:$mm$suffix)';
  }

  /// "Today" / "Yesterday" / "Jun 30, 2026" — matches the Notification
  /// list's date column, which only ever spells out the two most recent
  /// days and falls back to [mediumDate] for anything older. Both
  /// `date` and "now" are compared as Riyadh calendar days; see
  /// [toRiyadh].
  static String relativeDay(DateTime date) {
    final nowRiyadh = toRiyadh(DateTime.now());
    final today = DateTime(nowRiyadh.year, nowRiyadh.month, nowRiyadh.day);
    final riyadhDate = toRiyadh(date);
    final day = DateTime(riyadhDate.year, riyadhDate.month, riyadhDate.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'today'.tr;
    if (diff == 1) return 'yesterday'.tr;
    return mediumDate(date);
  }
}