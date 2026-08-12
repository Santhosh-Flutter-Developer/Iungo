import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/selection_list_page.dart';

class SelectBuildingPage extends GetView<NewServiceRequestController> {
  const SelectBuildingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SelectionListPage(
        title: 'select_building'.tr,
        searchHint: 'search_buildings'.tr,
        items: NewServiceRequestController.buildings,
        selectedItem: controller.selectedBuilding.value,
        onSelected: controller.selectBuilding,
      ),
    );
  }
}
