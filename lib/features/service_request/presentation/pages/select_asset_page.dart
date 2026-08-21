import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/selection_list_page.dart';

class SelectAssetPage extends StatefulWidget {
  const SelectAssetPage({super.key});

  @override
  State<SelectAssetPage> createState() => _SelectAssetPageState();
}

class _SelectAssetPageState extends State<SelectAssetPage> {
  final controller = Get.find<NewServiceRequestController>();

  @override
  void initState() {
    super.initState();
    controller.onOpenAssetPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SelectionListPage(
        title: 'select_asset'.tr,
        searchHint: 'search_assets'.tr,
        items: controller.assetOptions.map((o) => o.label).toList(),
        selectedItem: controller.selectedAsset.value,
        onSelected: controller.selectAsset,
        isLoading: controller.isLoadingAssets.value,
      ),
    );
  }
}