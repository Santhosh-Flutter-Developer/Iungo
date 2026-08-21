import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/selection_list_page.dart';

class SelectSitePage extends StatefulWidget {
  const SelectSitePage({super.key});

  @override
  State<SelectSitePage> createState() => _SelectSitePageState();
}

class _SelectSitePageState extends State<SelectSitePage> {
  final controller = Get.find<NewServiceRequestController>();

  @override
  void initState() {
    super.initState();
    // Fetched once when the page opens — NOT from build(), since Obx
    // rebuilds (triggered by the fetch itself) would otherwise re-fire
    // this on every frame.
    controller.onOpenSitePicker();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SelectionListPage(
        title: 'select_site'.tr,
        searchHint: 'search_sites'.tr,
        items: controller.siteOptions.map((o) => o.label).toList(),
        selectedItem: controller.selectedSite.value,
        onSelected: controller.selectSite,
        isLoading: controller.isLoadingSites.value,
      ),
    );
  }
}