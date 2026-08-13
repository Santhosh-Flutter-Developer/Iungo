import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/presentation/widgets/detail_info_tile.dart';
import 'package:iungo/features/service_request/presentation/widgets/status_badge.dart';

class DetailOverviewTab extends StatelessWidget {
  const DetailOverviewTab({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        StatusBadge(status: request.status),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.headingBlueGrey),
            const SizedBox(width: 8),
            Text(
              AppDateFormat.mediumDateWithTime(request.raisedAt),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          request.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '# ${request.id}',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.headingBlueGrey,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.person_outline,
                size: 18, color: AppColors.headingBlueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                request.requester,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.headingBlueGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.call_outlined,
                size: 18, color: AppColors.headingBlueGrey),
            const SizedBox(width: 8),
            Text(
              request.phone ?? '--',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'description'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.labelGrey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                request.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.headingBlueGrey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 20),
        Text(
          'assigned_technician'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 14),
        if (request.assignedTechnician == null)
          Text(
            'not_assigned'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          )
        else
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(request.assignedTechnician!),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.assignedTechnician!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 20),
        Text(
          'other_information'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 18),
        DetailInfoTile(
          icon: Icons.home_outlined,
          label: 'site'.tr,
          value: request.site,
        ),
        DetailInfoTile(
          icon: Icons.location_on_outlined,
          label: 'building'.tr,
          value: request.building ?? '--',
        ),
        DetailInfoTile(
          icon: Icons.folder_outlined,
          label: 'classification'.tr,
          value: request.classification.labelKey.tr,
        ),
        DetailInfoTile(
          icon: Icons.tag,
          label: 'space_asset'.tr,
          value: request.spaceAsset ?? '--',
        ),
        DetailInfoTile(
          icon: Icons.trending_up,
          label: 'priority'.tr,
          value: request.priority.labelKey.tr,
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
