import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_filter.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_status.dart';
import 'package:iungo/features/service_request/presentation/controllers/service_request_list_controller.dart';
import 'package:iungo/features/service_request/presentation/pages/due_date_range_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/filter_select_field.dart';

/// Full "Filter" screen: two tabs — "Filter" (type/status/priority/due
/// date + Apply) and "Find Ticket" (lookup by id). Matches the reference
/// screenshots exactly.
class ServiceRequestFilterPage extends StatefulWidget {
  const ServiceRequestFilterPage({super.key, required this.controller});

  final ServiceRequestListController controller;

  static Future<void> show(
    BuildContext context, {
    required ServiceRequestListController controller,
  }) {
    return Get.to(() => ServiceRequestFilterPage(controller: controller)) ??
        Future.value();
  }

  @override
  State<ServiceRequestFilterPage> createState() =>
      _ServiceRequestFilterPageState();
}

class _ServiceRequestFilterPageState extends State<ServiceRequestFilterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  late ServiceRequestFilter _draft = widget.controller.filter.value;
  late final _ticketIdController = TextEditingController(
    text: widget.controller.findTicketId.value?.toString() ?? '',
  );

  @override
  void initState() {
    super.initState();
    widget.controller.ensureFilterOptionsLoaded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ticketIdController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _draft = const ServiceRequestFilter();
      _ticketIdController.clear();
    });
    widget.controller.clearFilter();
    Get.back();
  }

  Future<void> _pickDueDateRange() async {
    final range = await DueDateRangePage.show(
      context,
      initialStart: _draft.dueDateStart,
      initialEnd: _draft.dueDateEnd,
    );
    if (range == null) return;
    setState(() {
      _draft = _draft.copyWith(
        dueDateStart: range.start,
        dueDateEnd: range.end,
      );
    });
  }

  void _applyFilter() {
    widget.controller.applyFilter(_draft);
    Get.back();
  }

  void _findTicket() {
    final id = int.tryParse(_ticketIdController.text.trim());
    if (id == null) return;
    widget.controller.findTicket(id);
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
          FilterSelectField<ServiceRequestOption>(
            label: 'service_request_type'.tr,
            hint: 'select_service_request_type'.tr,
            options: ServiceRequestOption.values,
            optionLabel: (o) => o.labelKey.tr,
            value: _draft.type,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(type: v)),
          ),
          const SizedBox(height: 20),
          Obx(
            () => FilterSelectField<ServiceRequestStatus>(
              label: 'select_status'.tr,
              hint: 'select_status'.tr,
              options: widget.controller.statusFilterOptions.isNotEmpty
                  ? widget.controller.statusFilterOptions
                  : ServiceRequestStatusX.filterOptions,
              optionLabel: (o) => o.labelKey.tr,
              value: _draft.status,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(status: v)),
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => FilterSelectField<ServiceRequestPriority>(
              label: 'select_priority'.tr,
              hint: 'select_priority'.tr,
              options: widget.controller.priorityFilterOptions.isNotEmpty
                  ? widget.controller.priorityFilterOptions
                  : ServiceRequestPriority.values,
              optionLabel: (o) => o.labelKey.tr,
              value: _draft.priority,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(priority: v)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'set_due_date'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _pickDueDateRange,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _draft.dueDateStart == null
                          ? 'set_due_date'.tr
                          : _fmtRange(_draft.dueDateStart, _draft.dueDateEnd),
                      style: TextStyle(
                        fontSize: 15,
                        color: _draft.dueDateStart == null
                            ? const Color(0xFF9A9A9A)
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                  if (_draft.dueDateStart != null)
                    InkWell(
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(clearDueDate: true),
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
            'find_ticket_by_id'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ticketIdController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'ticket_id'.tr,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
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