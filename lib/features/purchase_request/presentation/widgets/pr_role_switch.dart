import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_view_role.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_role_controller.dart';

/// Dev-only "preview as Requestor / Approver" switch for the PR
/// Dashboard AppBar. See [PrViewRole] — this exists purely so both UIs
/// can be reviewed in the running app before the real role comes from
/// the API, and should be removed once it does.
class PrRoleSwitch extends StatelessWidget {
  const PrRoleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final roleController = Get.find<PrRoleController>();
    return Obx(
      () => PopupMenuButton<PrViewRole>(
        tooltip: 'pr_preview_role'.tr,
        icon: Icon(
          roleController.isApprover
              ? Icons.verified_user_outlined
              : Icons.person_outline,
          color: AppColors.white,
        ),
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (value) {
          roleController.setRole(value);
          AppSnackbar.showSuccess(
            '${'pr_previewing_as'.tr} ${value.labelKey.tr}',
          );
        },
        itemBuilder: (context) => PrViewRole.values
            .map(
              (role) => PopupMenuItem<PrViewRole>(
                value: role,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 18,
                      color: roleController.role.value == role
                          ? AppColors.textDark
                          : Colors.transparent,
                    ),
                    const SizedBox(width: 10),
                    Text(role.labelKey.tr),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
