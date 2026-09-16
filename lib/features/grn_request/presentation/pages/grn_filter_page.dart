import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/grn_request/domain/entities/grn_request_filter.dart';
import 'package:iungo/features/grn_request/presentation/controllers/grn_filter_controller_like.dart';
import 'package:iungo/features/service_request/presentation/pages/due_date_range_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_select_field.dart';

/// "Filter" screen for the GRN Dashboard — two tabs, mirroring
/// `PrFilterPage` exactly: "Filter" (Contract + Created-date range +
/// Apply) and "Find Ticket" (lookup by GRN Number).
///
/// Driven by [GrnFilterControllerLike] rather than the concrete
/// controller, so the same screen can later drive a live, API-backed
/// controller too.
class GrnFilterPage extends StatefulWidget {
  const GrnFilterPage({super.key, required this.controller});

  final GrnFilterControllerLike controller;

  static Future<void> show(
    BuildContext context, {
    required GrnFilterControllerLike controller,
  }) {
    return Get.to(() => GrnFilterPage(controller: controller)) ??
        Future.value();
  }

  @override
  State<GrnFilterPage> createState() => _GrnFilterPageState();
}

class _GrnFilterPageState extends State<GrnFilterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  late GrnRequestFilter _draft = widget.controller.filter.value;
  late final _numberController = TextEditingController(
    text: widget.controller.findNumber.value ?? '',
  );

  @override
  void dispose() {
    _tabController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _draft = const GrnRequestFilter();
      _numberController.clear();
    });
    widget.controller.clearFilter();
    Get.back();
  }

  Future<void> _pickCreatedDateRange() async {
    final range = await DueDateRangePage.show(
      context,
      initialStart: _draft.createdDateStart,
      initialEnd: _draft.createdDateEnd,
    );
    if (range == null) return;
    setState(() {
      _draft = _draft.copyWith(
        createdDateStart: range.start,
        createdDateEnd: range.end,
      );
    });
  }

  void _applyFilter() {
    widget.controller.applyFilter(_draft);
    Get.back();
  }

  void _findTicket() {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;
    widget.controller.findTicket(number);
    Get.back();
  }

  String _fmtRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    String f(DateTime d) =>
        '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    return '${f(start)} - ${f(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      'filter'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.headingBlueGrey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: Text(
                      'clear'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'filter'.tr),
                Tab(text: 'find_ticket'.tr),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFilterTab(),
                  _buildFindTicketTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterSelectField<String>(
            label: 'pr_select_contract'.tr,
            hint: 'pr_select_contract'.tr,
            options: widget.controller.contractOptions,
            optionLabel: (o) => o,
            value: _draft.contract,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(contract: v)),
          ),
          const SizedBox(height: 20),
          Text(
            'set_created_date'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _pickCreatedDateRange,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _draft.createdDateStart == null
                          ? 'set_created_date'.tr
                          : _fmtRange(
                              _draft.createdDateStart, _draft.createdDateEnd),
                      style: TextStyle(
                        fontSize: 15,
                        color: _draft.createdDateStart == null
                            ? const Color(0xFF9A9A9A)
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                  if (_draft.createdDateStart != null)
                    InkWell(
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(clearCreatedDate: true),
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.inputIcon),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.inputIcon),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _applyFilter,
              child: Text('apply_filter'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'grn_find_by_number'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _numberController,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'grn_number'.tr,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _findTicket,
              child: Text('find_ticket'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
