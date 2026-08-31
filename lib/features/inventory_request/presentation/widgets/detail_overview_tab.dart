import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_line_item.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/inventory_request/presentation/widgets/inventory_reservation_status_badge.dart';

/// Overview tab of the Inventory Request Detail View. Uses the same
/// AppBar/tab-bar chrome, fonts, colors and spacing rhythm as the Work
/// Order Detail View's Overview tab (see [DetailOverviewTab]), but lays
/// out the actual fields to match the reference admin-panel screenshot:
/// a description block, a two-column field grid (Requested/Required
/// Time, Requested By/For, Client Approval Authorities/Service Line,
/// Status/Is Spare Part Request), and a Line Items table.
class InventoryRequestDetailOverviewTab extends StatelessWidget {
  const InventoryRequestDetailOverviewTab({super.key, required this.request});

  final InventoryRequest request;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Row(
          children: [
            InventoryReservationStatusBadge(status: request.reservationStatus),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.headingBlueGrey),
            const SizedBox(width: 8),
            Text(
              AppDateFormat.mediumDateWithTime(request.createdTime),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.headingBlueGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          request.name,
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
        const SizedBox(height: 20),
        Text(
          request.description.trim().isEmpty
              ? 'no_description_provided'.tr
              : request.description,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.headingBlueGrey,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 20),
        Text(
          'inventory_details'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 18),
        _FieldPairRow(
          leftLabel: 'requested_time'.tr,
          leftValue: AppDateFormat.mediumDate(request.requestedTime),
          rightLabel: 'required_time'.tr,
          rightValue: AppDateFormat.mediumDate(request.requiredTime),
        ),
        _FieldPairRow(
          leftLabel: 'requested_by'.tr,
          leftValue: request.requestedBy,
          rightLabel: 'requested_for'.tr,
          rightValue: request.requestedFor,
        ),
        _FieldPairRow(
          leftLabel: 'client_approval_authorities'.tr,
          leftValue: request.clientApprovalAuthorities.isEmpty
              ? '--'
              : request.clientApprovalAuthorities.join(', '),
          rightLabel: 'service_line'.tr,
          rightValue: request.serviceLine,
        ),
        _FieldPairRow(
          leftLabel: 'status'.tr,
          leftValue: (request.status ?? '').trim().isEmpty
              ? '--'
              : request.status!,
          rightLabel: 'is_spare_part_request_or_not'.tr,
          rightValue: request.isSparePartRequest ? 'yes'.tr : 'no'.tr,
          isLast: true,
        ),
        const SizedBox(height: 10),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 20),
        Text(
          'line_items'.tr,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 14),
        for (final item in request.lineItems) _LineItemTile(item: item),
      ],
    );
  }
}

/// One "Requested Time / Required Time"-style row of the field grid —
/// label above value in each of two columns, matching the reference
/// screenshot's layout exactly.
class _FieldPairRow extends StatelessWidget {
  const _FieldPairRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.isLast = false,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _FieldItem(label: leftLabel, value: leftValue)),
          const SizedBox(width: 16),
          Expanded(child: _FieldItem(label: rightLabel, value: rightValue)),
        ],
      ),
    );
  }
}

class _FieldItem extends StatelessWidget {
  const _FieldItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

/// One card in the "Line Items" table — the item name/code up top, then
/// a row of Store Room / Requested / Available / Issued quantities,
/// styled like a compact version of the reference's Line Items table.
class _LineItemTile extends StatelessWidget {
  const _LineItemTile({required this.item});

  final InventoryLineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.itemName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.itemCode,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.storeRoom,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.headingBlueGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QtyStat(
                  label: 'requested_qty'.tr,
                  value: item.requestedQty.toString(),
                ),
              ),
              Expanded(
                child: _QtyStat(
                  label: 'available_qty'.tr,
                  value: item.availableQty.toString(),
                ),
              ),
              Expanded(
                child: _QtyStat(
                  label: 'issued_qty'.tr,
                  value: item.issuedQty.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyStat extends StatelessWidget {
  const _QtyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
