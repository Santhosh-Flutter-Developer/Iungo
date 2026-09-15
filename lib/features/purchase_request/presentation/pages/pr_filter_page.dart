import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_filter.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_filter_controller_like.dart';
import 'package:iungo/features/service_request/presentation/pages/due_date_range_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_select_field.dart';

/// "Filter" screen for the PR Dashboard — Contract and Created-date
/// range, matching exactly what was asked for. Mirrors
/// `InventoryRequestFilterPage`'s single "Filter" tab (no Find Ticket
/// tab here, since the PR Dashboard has its own dedicated Search
/// screen instead).
///
/// Driven by [PrFilterControllerLike] rather than the concrete
/// controller, so the same screen can later drive a live, API-backed
/// controller too.
class PrFilterPage extends StatefulWidget {
  const PrFilterPage({super.key, required this.controller});

  final PrFilterControllerLike controller;

  static Future<void> show(
    BuildContext context, {
    required PrFilterControllerLike controller,
  }) {
    return Get.to(() => PrFilterPage(controller: controller)) ??
        Future.value();
  }

  @override
  State<PrFilterPage> createState() => _PrFilterPageState();
}

class _PrFilterPageState extends State<PrFilterPage> {
  late PurchaseRequestFilter _draft = widget.controller.filter.value;

  void _clear() {
    setState(() => _draft = const PurchaseRequestFilter());
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
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
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
                                    : _fmtRange(_draft.createdDateStart,
                                        _draft.createdDateEnd),
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
                                  () => _draft =
                                      _draft.copyWith(clearCreatedDate: true),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
