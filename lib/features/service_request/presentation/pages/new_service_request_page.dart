import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/pages/select_asset_page.dart';
import 'package:iungo/features/service_request/presentation/pages/select_building_page.dart';
import 'package:iungo/features/service_request/presentation/pages/select_location_page.dart';
import 'package:iungo/features/service_request/presentation/pages/select_site_page.dart';
import 'package:iungo/features/service_request/presentation/widgets/add_attachment_sheet.dart';
import 'package:iungo/features/service_request/presentation/widgets/attachment_upload_box.dart';
import 'package:iungo/features/service_request/presentation/widgets/classification_dropdown.dart';
import 'package:iungo/features/service_request/presentation/widgets/select_field.dart';
import 'package:iungo/features/service_request/presentation/widgets/submit_fab.dart';
import 'package:iungo/features/service_request/presentation/widgets/user_location_card.dart';

class NewServiceRequestPage extends GetView<NewServiceRequestController> {
  const NewServiceRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.formHeaderBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'new_service_request'.tr,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SubmitFab(onPressed: controller.submit),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'subject'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.subjectController,
                style:
                    const TextStyle(fontSize: 15, color: AppColors.textDark),
                decoration: InputDecoration(hintText: 'enter_subject'.tr),
              ),
              const SizedBox(height: 20),
              Text(
                'description'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.descriptionController,
                minLines: 8,
                maxLines: 8,
                style:
                    const TextStyle(fontSize: 15, color: AppColors.textDark),
                decoration: InputDecoration(hintText: 'enter_description'.tr),
              ),
              const SizedBox(height: 20),
              ClassificationDropdown(controller: controller),
              const SizedBox(height: 20),
              Obx(
                () => SelectField(
                  label: 'site'.tr,
                  hint: 'select_site'.tr,
                  value: controller.selectedSite.value,
                  onTap: () => Get.to(() => const SelectSitePage()),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => SelectField(
                  label: 'building'.tr,
                  hint: 'select_building'.tr,
                  value: controller.selectedBuilding.value,
                  onTap: () => Get.to(() => const SelectBuildingPage()),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => SelectField(
                  label: 'asset'.tr,
                  hint: 'select_asset'.tr,
                  value: controller.selectedAsset.value,
                  onTap: () => Get.to(() => const SelectAssetPage()),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'user_location'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => UserLocationCard(
                  address: controller.address.value,
                  latitude: controller.latitude.value,
                  longitude: controller.longitude.value,
                  onEdit: () => Get.to(() => const SelectLocationPage()),
                  onRefresh: () {},
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'attachments'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => AttachmentUploadBox(
                  loading: controller.isPickingAttachment.value,
                  onTap: () => AddAttachmentSheet.show(
                    context,
                    onCameraTap: controller.pickFromCamera,
                    onGalleryTap: controller.pickFileOrImage,
                  ),
                ),
              ),
              Obx(
                () => controller.attachments.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final attachment in controller.attachments)
                              _AttachmentTile(
                                name: attachment.name,
                                onRemove: () =>
                                    controller.removeAttachment(attachment),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 18, color: AppColors.inputIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                size: 18, color: AppColors.textMuted),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
