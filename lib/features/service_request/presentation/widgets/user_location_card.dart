import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

class UserLocationCard extends StatelessWidget {
  const UserLocationCard({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.onEdit,
    required this.onRefresh,
  });

  final String address;
  final String latitude;
  final String longitude;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.headingBlueGrey),
              const SizedBox(width: 6),
              Text(
                'address'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.headingBlueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LatLongColumn(
                  icon: Icons.circle_outlined,
                  label: 'latitude'.tr,
                  value: latitude,
                ),
              ),
              Expanded(
                child: _LatLongColumn(
                  icon: Icons.circle_outlined,
                  label: 'longitude'.tr,
                  value: longitude,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _LinkButton(
                icon: Icons.refresh,
                label: 'refresh'.tr,
                onTap: onRefresh,
              ),
              const SizedBox(width: 24),
              _LinkButton(
                icon: Icons.edit_outlined,
                label: 'edit'.tr,
                onTap: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatLongColumn extends StatelessWidget {
  const _LatLongColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.headingBlueGrey),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
