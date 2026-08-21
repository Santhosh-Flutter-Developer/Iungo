import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/selection_list_page.dart';

class SelectBuildingPage extends StatefulWidget {
  const SelectBuildingPage({super.key});

  @override
  State<SelectBuildingPage> createState() => _SelectBuildingPageState();
}

class _SelectBuildingPageState extends State<SelectBuildingPage> {
  final controller = Get.find<NewServiceRequestController>();

  @override
  void initState() {
    super.initState();
    controller.onOpenBuildingPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SelectionListPage(
        title: 'select_building'.tr,
        searchHint: 'search_buildings'.tr,
        items: controller.buildingOptions.map((o) => o.label).toList(),
        selectedItem: controller.selectedBuilding.value,
        onSelected: controller.selectBuilding,
        isLoading: controller.isLoadingBuildings.value,
      ),
    );
  }
}