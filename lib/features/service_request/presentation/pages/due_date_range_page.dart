import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// "Select range" calendar — a scrollable list of month grids where the
/// user taps a start date then an end date. Matches the reference
/// screenshot: X / Save header, "Start Date – End Date" row with an edit
/// pencil, weekday headers, and month sections.
class DueDateRangePage extends StatefulWidget {
  const DueDateRangePage({super.key, this.initialStart, this.initialEnd});

  final DateTime? initialStart;
  final DateTime? initialEnd;

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTime? initialStart,
    DateTime? initialEnd,
  }) {
    return Get.to<DateTimeRange?>(
          () => DueDateRangePage(
            initialStart: initialStart,
            initialEnd: initialEnd,
          ),
        ) ??
        Future.value(null);
  }

  @override
  State<DueDateRangePage> createState() => _DueDateRangePageState();
}

class _DueDateRangePageState extends State<DueDateRangePage> {
  DateTime? _start;
  DateTime? _end;

  static const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  String _fmt(DateTime? d) =>
      d == null ? '' : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime day) {
    if (_start == null || _end == null) return false;
    return day.isAfter(_start!) && day.isBefore(_end!);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      13,
      (i) => DateTime(now.year, now.month + i - 1),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Get.back(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: (_start != null && _end != null)
                        ? () => Get.back(
                              result: DateTimeRange(start: _start!, end: _end!),
                            )
                        : null,
                    child: Text(
                      'save'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: (_start != null && _end != null)
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'select_range'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (_start == null)
                              ? 'start_date_end_date'.tr
                              : '${_fmt(_start)} — ${_fmt(_end)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: (_start == null)
                                ? AppColors.textMuted
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.headingBlueGrey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 20, color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: months.length,
                itemBuilder: (context, index) =>
                    _MonthGrid(month: months[index], state: this),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget monthLabel(DateTime month) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          '${_monthNames[month.month - 1]} ${month.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.headingBlueGrey,
          ),
        ),
      );
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.state});

  final DateTime month;
  final _DueDateRangePageState state;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7; // Sunday-start grid

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(_DayCell(date: date, state: state));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        state.monthLabel(month),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: cells,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.state});

  final DateTime date;
  final _DueDateRangePageState state;

  @override
  Widget build(BuildContext context) {
    final isStart = state._start != null && state._isSameDay(date, state._start!);
    final isEnd = state._end != null && state._isSameDay(date, state._end!);
    final inRange = state._inRange(date);
    final isToday = state._isSameDay(date, DateTime.now());

    return InkWell(
      onTap: () => state._onDayTap(date),
      customBorder: const CircleBorder(),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: inRange
              ? AppColors.drawerSelectedBackground
              : (isStart || isEnd)
                  ? AppColors.primary
                  : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isStart && !isEnd
              ? Border.all(color: AppColors.primary)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: (isStart || isEnd) ? FontWeight.w700 : FontWeight.w400,
            color: (isStart || isEnd) ? AppColors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
