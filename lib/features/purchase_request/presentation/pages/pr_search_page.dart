import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/purchase_request/presentation/bindings/pr_detail_binding.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_search_controller.dart';
import 'package:iungo/features/purchase_request/presentation/pages/pr_detail_page.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/purchase_request_card.dart';

/// Search screen for the PR Dashboard — matches PR Number or Contract
/// against the local data set. Same white AppBar + inline text field
/// chrome as `InventoryRequestSearchPage`, without its field-scope
/// dropdown (PR search only ever matches those two fields).
class PrSearchPage extends GetView<PrSearchController> {
  const PrSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _SearchAppBar(controller: controller),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.query.value.trim().isEmpty) {
            return Center(
              child: Text(
                'search'.tr,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
            );
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
            itemBuilder: (context, index) => PurchaseRequestCard(
              request: controller.results[index],
              onTap: () => Get.to(
                () => const PrDetailPage(),
                binding: PrDetailBinding(controller.results[index]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SearchAppBar({required this.controller});

  final PrSearchController controller;

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
        onSubmitted: controller.onQuerySubmitted,
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: 'pr_search_hint'.tr,
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
