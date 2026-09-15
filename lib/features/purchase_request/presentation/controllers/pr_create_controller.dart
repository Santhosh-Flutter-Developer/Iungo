import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/purchase_request/data/purchase_request_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/material_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';

/// Drives the "Add Purchase Request" form — General Specification
/// fields, the "Add Items" line-item builder, quotation upload, and the
/// VAT summary. UI-only: [submit] writes into
/// [PurchaseRequestRepository]'s local data set rather than a real API,
/// matching the rest of this feature.
class PrCreateController extends GetxController {
  PrCreateController(this._repository);

  final PurchaseRequestRepository _repository;

  List<String> get contractOptions => PurchaseRequestRepository.contracts;
  List<String> get categoryOptions => PurchaseRequestRepository.categories;
  List<MaterialOption> get materialOptions =>
      PurchaseRequestRepository.materialOptions;

  // ---- General Specification ---------------------------------------

  /// Always today — read-only, matches the reference form's "Date"
  /// field (distinct from the editable "Delivery Date").
  final DateTime requestDate = DateTime.now();

  final Rxn<String> contract = Rxn<String>();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController workOrderController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final Rx<DateTime> deliveryDate =
      DateTime.now().add(const Duration(days: 7)).obs;
  final Rxn<String> category = Rxn<String>();
  final TextEditingController purposeController = TextEditingController();

  // ---- Add Items row-builder -----------------------------------------

  final Rx<PurchaseRequestItemType> itemType =
      PurchaseRequestItemType.inventory.obs;
  final Rxn<MaterialOption> selectedMaterial = Rxn<MaterialOption>();
  final TextEditingController materialDescriptionController =
      TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  final RxList<PurchaseRequestItem> items = <PurchaseRequestItem>[].obs;

  // ---- Quotation attachments ------------------------------------------
  // Multiple files allowed — see PrCreatePage's attachment list.

  final RxList<String> quotationFileNames = <String>[].obs;

  final RxBool isSubmitting = false.obs;

  void setItemType(PurchaseRequestItemType type) {
    itemType.value = type;
    selectedMaterial.value = null;
    materialDescriptionController.clear();
    unitPriceController.clear();
  }

  void onMaterialSelected(MaterialOption? option) {
    selectedMaterial.value = option;
  }

  double get draftItemTotal {
    final qty = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(unitPriceController.text) ?? 0;
    return qty * price;
  }

  /// Adds the currently-filled-in row to [items] and resets the
  /// row-builder fields, ready for the next item — matches the
  /// reference video's "+ Add Item" behavior.
  void addItem() {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0;

    if (itemType.value == PurchaseRequestItemType.inventory &&
        selectedMaterial.value == null) {
      AppSnackbar.showError('pr_select_material_required'.tr);
      return;
    }
    if (itemType.value == PurchaseRequestItemType.nonInventory &&
        materialDescriptionController.text.trim().isEmpty) {
      AppSnackbar.showError('pr_enter_material_description_required'.tr);
      return;
    }
    if (quantity <= 0) {
      AppSnackbar.showError('pr_quantity_required'.tr);
      return;
    }
    if (unitPrice <= 0) {
      AppSnackbar.showError('pr_unit_price_required'.tr);
      return;
    }

    items.add(
      PurchaseRequestItem(
        type: itemType.value,
        materialCode: itemType.value == PurchaseRequestItemType.inventory
            ? selectedMaterial.value?.code
            : null,
        materialDescription:
            itemType.value == PurchaseRequestItemType.inventory
                ? (selectedMaterial.value?.description ?? '')
                : materialDescriptionController.text.trim(),
        remarks: remarksController.text.trim(),
        quantity: quantity,
        unitPrice: unitPrice,
      ),
    );

    selectedMaterial.value = null;
    materialDescriptionController.clear();
    quantityController.clear();
    unitPriceController.clear();
    remarksController.clear();
  }

  void removeItem(int index) => items.removeAt(index);

  Future<void> pickQuotation() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        quotationFileNames.addAll(
          result.files.map((f) => f.name).where(
                (name) => !quotationFileNames.contains(name),
              ),
        );
      }
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    }
  }

  void removeQuotationAt(int index) => quotationFileNames.removeAt(index);

  Future<void> pickDeliveryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: deliveryDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) deliveryDate.value = picked;
  }

  // ---- Totals ---------------------------------------------------------

  double get totalLines => items.fold(0.0, (sum, item) => sum + item.total);

  /// Administrative expenses are server/config-driven in the reference
  /// design (shown read-only as "0 %") — fixed at 0 here since there's
  /// no such setting to source it from yet.
  double get administrativeExpensesPercent => 0;

  double get totalBeforeVat => totalLines;
  double get vatAmount => totalBeforeVat * 0.15;
  double get totalAmount => totalBeforeVat + vatAmount;

  Future<bool> submit() async {
    if (contract.value == null) {
      AppSnackbar.showError('pr_select_contract_required'.tr);
      return false;
    }
    if (items.isEmpty) {
      AppSnackbar.showError('pr_add_at_least_one_item'.tr);
      return false;
    }

    isSubmitting.value = true;
    try {
      await _repository.addPurchaseRequest(
        contract: contract.value!,
        location: locationController.text.trim(),
        workOrderNo: workOrderController.text.trim(),
        requestDescription: descriptionController.text.trim(),
        deliveryDate: deliveryDate.value,
        category: category.value ?? '',
        purpose: purposeController.text.trim(),
        items: items.toList(),
        quotationFileNames: quotationFileNames.toList(),
      );
      AppSnackbar.showSuccess('pr_submitted_success'.tr);
      return true;
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    locationController.dispose();
    workOrderController.dispose();
    descriptionController.dispose();
    purposeController.dispose();
    materialDescriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    remarksController.dispose();
    super.onClose();
  }
}