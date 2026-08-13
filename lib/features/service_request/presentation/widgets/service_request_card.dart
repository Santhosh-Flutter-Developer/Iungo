import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/domain/entities/service_request.dart';
import 'package:iungo/features/service_request/domain/entities/service_request_priority.dart';
import 'package:iungo/features/service_request/presentation/widgets/status_badge.dart';

/// One card in the "My Service Requests" list — id + status row, bold
/// title, a two-line description, then a light-grey info strip with
/// requester / site / priority.
class ServiceRequestCard extends StatelessWidget {
  const ServiceRequestCard({super.key, required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TicketIdChip(id: request.id),
              const Spacer(),
              StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            request.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.person_outline,
                        label: request.requester,
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.location_on_outlined,
                        label: request.site,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoItem(
                  icon: Icons.access_time,
                  label: request.priority == ServiceRequestPriority.noPriority
                      ? 'priority_no_priority'.tr
                      : request.priority.labelKey.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
