import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/selection_list_page.dart';

class SelectSitePage extends GetView<NewServiceRequestController> {
  const SelectSitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SelectionListPage(
        title: 'select_site'.tr,
        searchHint: 'search_sites'.tr,
        items: NewServiceRequestController.sites,
        selectedItem: controller.selectedSite.value,
        onSelected: controller.selectSite,
      ),
    );
  }
}
