import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/search_scope.dart';
import 'package:iungo/features/work_order/presentation/controllers/work_order_search_controller.dart';
import 'package:iungo/features/work_order/presentation/widgets/work_order_card.dart';

/// "My Work Orders" search screen. White app bar with an inline text
/// field, a field-scope dropdown ("All Fields" / "Ticket Id" / "Subject"
/// / "Description"), and a close icon. Body cycles through: idle prompt
/// -> debounce spinner -> results list or "No Results Found".
class WorkOrderSearchPage extends GetView<WorkOrderSearchController> {
  const WorkOrderSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SearchAppBar(controller: controller),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.query.value.trim().isEmpty) {
            return const _IdlePrompt();
          }
          if (controller.isSearching.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (controller.results.isEmpty) {
            return const _NoResultsState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: controller.results.length,
            itemBuilder: (context, index) =>
                WorkOrderCard(workOrder: controller.results[index]),
          );
        }),
      ),
    );
  }
}

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SearchAppBar({required this.controller});

  final WorkOrderSearchController controller;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.grey),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: TextField(
        autofocus: true,
        onChanged: controller.onQueryChanged,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: 'search'.tr,
          hintStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.inputIcon,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
        ),
      ),
      actions: [
        _ScopeDropdownButton(controller: controller),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

class _ScopeDropdownButton extends StatelessWidget {
  const _ScopeDropdownButton({required this.controller});

  final WorkOrderSearchController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SearchScope>(
      icon: const Icon(Icons.sort, color: Colors.grey),
      offset: const Offset(0, 40),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      onSelected: controller.onScopeChanged,
      itemBuilder: (context) => SearchScope.values
          .map(
            (item) => PopupMenuItem<SearchScope>(
              value: item,
              child: _ScopeMenuRow(
                scope: item,
                selected: controller.scope.value == item,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ScopeMenuRow extends StatelessWidget {
  const _ScopeMenuRow({required this.scope, required this.selected});

  final SearchScope scope;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check,
          size: 18,
          color: selected ? AppColors.textDark : AppColors.divider,
        ),
        const SizedBox(width: 12),
        Text(
          scope.labelKey.tr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _IdlePrompt extends StatelessWidget {
  const _IdlePrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'search'.tr,
        style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              children: [
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Icon(
                    Icons.search,
                    size: 52,
                    color: Colors.grey.shade400,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 18,
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_results_found'.tr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'try_different_keywords'.tr,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}