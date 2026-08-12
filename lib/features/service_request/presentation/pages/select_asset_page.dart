import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/selection_list_page.dart';

class SelectAssetPage extends GetView<NewServiceRequestController> {
  const SelectAssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final building = controller.selectedBuilding.value;
      final items = building == null
          ? const <String>[]
          : controller.assetsFor(building);
      return SelectionListPage(
        title: 'select_asset'.tr,
        searchHint: 'search_assets'.tr,
        items: items,
        selectedItem: controller.selectedAsset.value,
        onSelected: controller.selectAsset,
      );
    });
  }
}
