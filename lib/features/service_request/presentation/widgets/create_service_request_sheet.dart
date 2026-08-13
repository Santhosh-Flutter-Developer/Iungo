import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_option.dart';
import 'package:iungo/features/service_request/presentation/bindings/new_service_request_binding.dart';
import 'package:iungo/features/service_request/presentation/pages/new_service_request_page.dart';

class CreateServiceRequestSheet extends StatelessWidget {
  const CreateServiceRequestSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CreateServiceRequestSheet(),
    );
  }

  void _onOptionTap(ServiceRequestOption option) {
    Get.back();
    switch (option) {
      case ServiceRequestOption.serviceRequest:
        Get.to(
          () => const NewServiceRequestPage(),
          binding: NewServiceRequestBinding(),
        );
        break;
      // case ServiceRequestOption.cateringRequest:
      // case ServiceRequestOption.laundryRequest:
      //   // Static UI only — no dedicated screens for these yet.
      //   break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'create_service_request'.tr,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            for (final option in ServiceRequestOption.values)
              _OptionRow(
                option: option,
                onTap: () => _onOptionTap(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option, required this.onTap});

  final ServiceRequestOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(option.icon, size: 24, color: AppColors.textDark),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                option.labelKey.tr,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              size: 22,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
