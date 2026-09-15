import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/purchase_request/domain/entities/material_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_create_controller.dart';
import 'package:iungo/features/purchase_request/presentation/widgets/pr_searchable_select_field.dart';
import 'package:iungo/features/service_request/presentation/widgets/attachment_upload_box.dart';

/// "Add Purchase Request" form — General Specification fields, the "Add
/// Items" line-item builder, quotation upload, and the VAT summary.
/// Requestor-only entry point (see [PrRoleController]/`PrDashboardPage`).
/// Field-by-field layout matches the reference video exactly; dropdown
/// styling reuses `PrSearchableSelectField` (search + clear) for
/// Contract/Category/Type/Material Code.
class PrCreatePage extends GetView<PrCreateController> {
  const PrCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'pr_add_purchase_request'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader(labelKey: 'pr_general_specification'),
              const SizedBox(height: 16),
              Obx(
                () => PrSearchableSelectField<String>(
                  label: 'pr_contract_code'.tr,
                  hint: 'pr_select_contract_code'.tr,
                  options: controller.contractOptions,
                  optionLabel: (o) => o,
                  value: controller.contract.value,
                  onChanged: (v) => controller.contract.value = v,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'pr_date'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.prTileInactiveBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Text(
                  AppDateFormat.mediumDate(controller.requestDate),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'pr_location'.tr,
                controller: controller.locationController,
                hint: 'pr_enter_location'.tr,
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'pr_work_order_no'.tr,
                controller: controller.workOrderController,
                hint: 'pr_enter_work_order_no'.tr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'pr_request_description'.tr,
                controller: controller.descriptionController,
                hint: 'pr_enter_request_description'.tr,
                minLines: 3,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'pr_delivery_date'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => controller.pickDeliveryDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fmtDate(controller.deliveryDate.value),
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textDark),
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.inputIcon),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => PrSearchableSelectField<String>(
                  label: 'pr_category'.tr,
                  hint: 'pr_select_category'.tr,
                  options: controller.categoryOptions,
                  optionLabel: (o) => o,
                  value: controller.category.value,
                  onChanged: (v) => controller.category.value = v,
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'pr_purpose'.tr,
                controller: controller.purposeController,
                hint: 'pr_enter_purpose'.tr,
              ),
              const SizedBox(height: 28),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 24),
              const _SectionHeader(labelKey: 'pr_add_items'),
              const SizedBox(height: 16),
              Obx(
                () => PrSearchableSelectField<PurchaseRequestItemType>(
                  label: 'pr_type'.tr,
                  hint: 'pr_type'.tr,
                  options: PurchaseRequestItemType.values,
                  optionLabel: (o) => o.labelKey.tr,
                  value: controller.itemType.value,
                  allowClear: false,
                  onChanged: (v) {
                    if (v != null) controller.setItemType(v);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => controller.itemType.value ==
                        PurchaseRequestItemType.inventory
                    ? PrSearchableSelectField<MaterialOption>(
                        label: 'pr_material_code'.tr,
                        hint: 'pr_select_material_code'.tr,
                        options: controller.materialOptions,
                        optionLabel: (o) => o.displayLabel,
                        value: controller.selectedMaterial.value,
                        onChanged: controller.onMaterialSelected,
                      )
                    : _LabeledField(
                        label: 'pr_material_description'.tr,
                        controller: controller.materialDescriptionController,
                        hint: 'pr_enter_material_description'.tr,
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'pr_quantity'.tr,
                      controller: controller.quantityController,
                      hint: '0',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _LabeledField(
                      label: 'pr_unit_price'.tr,
                      controller: controller.unitPriceController,
                      hint: '0.00',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DraftTotalField(controller: controller),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'remarks'.tr,
                controller: controller.remarksController,
                hint: 'pr_enter_remarks'.tr,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: controller.addItem,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'pr_add_item'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                if (controller.items.isEmpty) {
                  return Center(
                    child: Text(
                      'pr_no_products_added_yet'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < controller.items.length; i++)
                      _DraftItemTile(
                        index: i + 1,
                        item: controller.items[i],
                        onDelete: () => controller.removeItem(i),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 28),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 24),
              const _SectionHeader(labelKey: 'pr_summary'),
              const SizedBox(height: 16),
              Text(
                'pr_quotation'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              AttachmentUploadBox(onTap: controller.pickQuotation),
              Obx(() {
                if (controller.quotationFileNames.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < controller.quotationFileNames.length;
                          i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    controller.quotationFileNames[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => controller.removeQuotationAt(i),
                                  child: const Icon(Icons.close,
                                      size: 18, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Obx(
                () => _TotalsCard(
                  totalLines: controller.totalLines,
                  administrativeExpensesPercent:
                      controller.administrativeExpensesPercent,
                  totalBeforeVat: controller.totalBeforeVat,
                  vatAmount: controller.vatAmount,
                  totalAmount: controller.totalAmount,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        'cancel'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : () async {
                                final ok = await controller.submit();
                                if (ok) Get.back(result: true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'submit'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      labelKey.tr,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: AppColors.labelGrey,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _DraftTotalField extends StatelessWidget {
  const _DraftTotalField({required this.controller});

  final PrCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pr_total'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        // Read-only — auto-computed as quantity × unit price, live as
        // either field changes (per feedback: this shouldn't be
        // editable).
        AnimatedBuilder(
          animation: Listenable.merge(
            [controller.quantityController, controller.unitPriceController],
          ),
          builder: (context, _) => Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.prTileInactiveBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              controller.draftItemTotal.toStringAsFixed(2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftItemTile extends StatelessWidget {
  const _DraftItemTile({
    required this.index,
    required this.item,
    required this.onDelete,
  });

  final int index;
  final PurchaseRequestItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${item.materialDescription.trim().isEmpty ? '--' : item.materialDescription}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (item.materialCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.materialCode!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.workOrderChipBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type.labelKey.tr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              InkWell(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline,
                      size: 20, color: AppColors.attachmentDeleteText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${'remarks'.tr}: '
            '${item.remarks.trim().isEmpty ? '--' : item.remarks}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.headingBlueGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _draftStat(
                  'pr_quantity'.tr,
                  item.quantity.toStringAsFixed(
                    item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
                  ),
                ),
              ),
              Expanded(
                child: _draftStat(
                    'pr_unit_price'.tr, item.unitPrice.toStringAsFixed(2)),
              ),
              Expanded(
                child:
                    _draftStat('pr_total'.tr, item.total.toStringAsFixed(2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _draftStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totalLines,
    required this.administrativeExpensesPercent,
    required this.totalBeforeVat,
    required this.vatAmount,
    required this.totalAmount,
  });

  final double totalLines;
  final double administrativeExpensesPercent;
  final double totalBeforeVat;
  final double vatAmount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _row('pr_total_lines'.tr, '${totalLines.toStringAsFixed(2)} SAR'),
          const SizedBox(height: 12),
          _row('pr_administrative_expenses'.tr,
              '${administrativeExpensesPercent.toStringAsFixed(0)} %'),
          const SizedBox(height: 12),
          _row('pr_total_before_vat'.tr,
              '${totalBeforeVat.toStringAsFixed(2)} SAR'),
          const SizedBox(height: 12),
          _row('pr_vat_15'.tr, '${vatAmount.toStringAsFixed(2)} SAR'),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),
          _row(
            'pr_total'.tr,
            '${totalAmount.toStringAsFixed(2)} SAR',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasized = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: emphasized ? AppColors.textDark : AppColors.headingBlueGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: emphasized ? AppColors.prStatusGreen : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}