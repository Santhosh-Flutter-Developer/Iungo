import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';
import 'package:iungo/features/service_request/presentation/widgets/select_field.dart';

/// "Classification" field: tapping it expands a small inline options list
/// directly below the field (not a separate page / modal), matching the
/// reference design.
class ClassificationDropdown extends StatelessWidget {
  const ClassificationDropdown({super.key, required this.controller});

  final NewServiceRequestController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.classification.value;
      final isExpanded = controller.isClassificationExpanded.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectField(
            label: 'classification'.tr,
            hint: 'select_classification'.tr,
            value: selected?.labelKey.tr,
            isExpanded: isExpanded,
            onTap: controller.toggleClassificationExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in RequestClassification.values)
                          _OptionTile(
                            label: option.labelKey.tr,
                            selected: selected == option,
                            onTap: () =>
                                controller.selectClassification(option),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      );
    });
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: selected
            ? AppColors.drawerSelectedBackground
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
