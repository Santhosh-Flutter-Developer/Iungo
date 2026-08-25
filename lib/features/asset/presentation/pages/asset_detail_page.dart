import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/asset/presentation/controllers/asset_detail_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/detail_info_tile.dart';

/// Shows the scanned asset's details — Name, Asset Id, Asset Code,
/// Description, Category, Location, Open/Closed PPM Count — matching
/// the reference "Asset Detail" screenshots row-for-row, and reusing
/// [DetailInfoTile] (the same icon/label/value row already used on
/// Service Request Detail's "Other Information" block) for the exact
/// same look.
class AssetDetailPage extends GetView<AssetDetailController> {
  const AssetDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward
                : Icons.arrow_back,
            color: AppColors.white,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text('asset_detail'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined, color: AppColors.white),
            tooltip: 'create_service_request'.tr,
            onPressed: controller.createServiceRequestForAsset,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final asset = controller.asset.value;
        if (controller.errorMessage.value.isNotEmpty || asset == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value
                        : 'something_went_wrong'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text('retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            DetailInfoTile(
              icon: Icons.person_outline,
              label: 'name'.tr,
              value: asset.name,
            ),
            DetailInfoTile(
              icon: Icons.mail_outline,
              label: 'asset_id'.tr,
              value: asset.id.toString(),
            ),
            DetailInfoTile(
              icon: Icons.edit_outlined,
              label: 'asset_code'.tr,
              value: asset.assetCode,
            ),
            DetailInfoTile(
              icon: Icons.insert_drive_file_outlined,
              label: 'description'.tr,
              value: asset.description,
            ),
            DetailInfoTile(
              icon: Icons.folder_outlined,
              label: 'category'.tr,
              value: asset.category,
            ),
            DetailInfoTile(
              icon: Icons.location_on_outlined,
              label: 'location'.tr,
              value: asset.location,
            ),
            DetailInfoTile(
              icon: Icons.work_outline,
              label: 'open_ppm_count'.tr,
              value: asset.openPpmCount.toString(),
            ),
            DetailInfoTile(
              icon: Icons.work_outline,
              label: 'closed_ppm_count'.tr,
              value: asset.closedPpmCount.toString(),
            ),
          ],
        );
      }),
    );
  }
}