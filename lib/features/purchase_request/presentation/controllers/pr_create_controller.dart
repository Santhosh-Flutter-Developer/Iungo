import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/data/models/pr_save_request_model.dart';
import 'package:iungo/features/purchase_request/data/pr_create_repository.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/material_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_summary.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/presentation/controllers/pr_attachment_upload.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';

/// Static "Category" dropdown values. The English value is exactly what
/// the save API receives; [prCategoryLabelKey] gives its translated label.
const List<String> kPrCategories = [
  'Cleaning',
  'Civil',
  'Mechanical',
  'Electrical',
  'Fire life safely',
  'Pest control',
  'Landscaping',
];

String prCategoryLabelKey(String category) =>
    'pr_category_${category.toLowerCase().replaceAll(' ', '_')}';

/// Drives the "Add Purchase Request" form — General Specification
/// fields (Contract Code from the API), the "Add Items" line-item
/// builder (Inventory materials from Facilio, lazily paged), quotation
/// uploads, the Summary maths, and the final save.
class PrCreateController extends GetxController {
  PrCreateController(this._repository, this._session);

  final PrCreateRepository _repository;
  final SessionService _session;

  List<String> get categoryOptions => kPrCategories;

  /// Materials fetched per request. The dropdown loads one page when
  /// opened and more only as the user scrolls / searches.
  static const int materialPageSize = 50;

  // ---- General Specification ---------------------------------------

  /// Always today — read-only, matches the reference form's "Date"
  /// field (distinct from the editable "Delivery Date").
  final DateTime requestDate = DateTime.now();

  final RxList<ContractOption> contracts = <ContractOption>[].obs;
  final Rxn<ContractOption> selectedContract = Rxn<ContractOption>();
  final RxBool isLoadingContracts = false.obs;
  final Rxn<String> contractsError = Rxn<String>();

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

  // ---- Inventory materials (paged / searchable dropdown) --------------

  final RxList<MaterialOption> materials = <MaterialOption>[].obs;

  /// True while the first page of a (re)load/search is in flight.
  final RxBool isLoadingMaterials = false.obs;
  final RxBool isLoadingMoreMaterials = false.obs;
  final RxBool hasMoreMaterials = false.obs;
  final Rxn<String> materialsError = Rxn<String>();

  /// A "load next page" request failed — auto-loading pauses and the
  /// dropdown footer offers a manual retry instead.
  final RxBool materialsLoadMoreFailed = false.obs;

  int _materialPage = 0;
  String _materialSearch = '';
  bool _materialsLoaded = false;

  /// Bumped on every fresh load/search so a slow, stale response can
  /// never overwrite newer results.
  int _materialRequestSeq = 0;
  Timer? _materialSearchDebounce;

  // ---- Quotation attachments ------------------------------------------
  // Multiple files allowed — each is uploaded individually as soon as
  // it is picked (see [pickQuotation]).

  final RxList<PrAttachmentUpload> attachments = <PrAttachmentUpload>[].obs;
  final RxBool isPickingAttachment = false.obs;
  int _attachmentSeq = 0;

  // ---- Submit ---------------------------------------------------------

  final RxBool isSubmitting = false.obs;

  /// The API's success message from the last [submit] (falls back to a
  /// translated default when the server sent none).
  String successMessage = '';

  @override
  void onInit() {
    super.onInit();
    // Deferred until the route has finished building, so a failure can
    // safely show a SnackBar.
    Future.microtask(loadContracts);
  }

  // ======================================================================
  // Contracts
  // ======================================================================

  Future<void> loadContracts() async {
    if (isLoadingContracts.value) return;
    isLoadingContracts.value = true;
    contractsError.value = null;
    try {
      final userId = _requireUserId();
      final result = await _repository.fetchContracts(userId: userId);
      contracts.assignAll(result);

      // Drop a selection that no longer exists in the refreshed list.
      final selected = selectedContract.value;
      if (selected != null && !result.contains(selected)) {
        selectedContract.value = null;
      }
    } on PrCreateException catch (e) {
      _reportContractsError(
        _messageFor(e, fallbackKey: 'pr_contract_load_failed'),
      );
    } catch (_) {
      _reportContractsError('pr_contract_load_failed'.tr);
    } finally {
      isLoadingContracts.value = false;
    }
  }

  /// Shown in the (empty) dropdown with a Retry, and also as a SnackBar
  /// since the dropdown is closed when this loads in the background.
  void _reportContractsError(String message) {
    contractsError.value = message;
    AppSnackbar.showError(message);
  }

  /// Stores the picked contract — its `contract_id` goes into the save
  /// payload and its `margin` drives "Administrative expenses".
  void onContractSelected(ContractOption? option) {
    selectedContract.value = option;
  }

  /// The logged-in user's `username` (sent as `creator_name`), from the
  /// existing login session.
  String _requireUsername() {
    final username = _session.authUsername.value;
    if (username == null || username.trim().isEmpty) {
      throw const PrCreateException(PrCreateFailure.unauthorized);
    }
    return username.trim();
  }

  /// The logged-in user's portal id, from the existing login session.
  String _requireUserId() {
    final userId = _session.authUserId.value;
    if (userId == null || userId.trim().isEmpty) {
      throw const PrCreateException(PrCreateFailure.unauthorized);
    }
    return userId.trim();
  }

  // ======================================================================
  // Item builder
  // ======================================================================

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
    return PrSummary.round2(qty * price);
  }

  /// Validates and appends the currently-filled-in row to [items], then
  /// resets the row-builder fields ready for the next item.
  void addItem() {
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text.trim()) ?? 0;
    final isInventory = itemType.value == PurchaseRequestItemType.inventory;

    if (isInventory && selectedMaterial.value == null) {
      AppSnackbar.showError('pr_select_material_required'.tr);
      return;
    }
    if (!isInventory && materialDescriptionController.text.trim().isEmpty) {
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

    final material = selectedMaterial.value;
    items.add(
      PurchaseRequestItem(
        type: itemType.value,
        // Inventory → the material's name ("Material Code"); Non
        // Inventory has no code (sent as "-" by the save model).
        materialCode: isInventory ? material?.name : null,
        materialId: isInventory ? material?.id : null,
        materialDescription: isInventory
            ? _inventoryDescription(material)
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

  /// A material without a description falls back to its name so the
  /// line never has a blank `material_desc`.
  String _inventoryDescription(MaterialOption? material) {
    if (material == null) return '';
    return material.description.trim().isNotEmpty
        ? material.description.trim()
        : material.name;
  }

  void removeItem(int index) => items.removeAt(index);

  // ======================================================================
  // Inventory materials — lazy loading, search, pagination
  // ======================================================================

  /// Called whenever the Material Code dropdown is opened. Loads the
  /// first page the first time (so nothing is fetched for Non Inventory
  /// items, or if the dropdown is never opened), and resets a stale
  /// search or a previous failure on later opens.
  void onMaterialDropdownOpened() {
    if (itemType.value != PurchaseRequestItemType.inventory) return;

    final needsReload = !_materialsLoaded ||
        _materialSearch.isNotEmpty ||
        materialsError.value != null;
    if (!needsReload) return;
    if (isLoadingMaterials.value && _materialSearch.isEmpty) return;

    _reloadMaterials(search: '');
  }

  /// Search box in the dropdown — debounced, applied server-side.
  void onMaterialSearchChanged(String query) {
    _materialSearchDebounce?.cancel();
    _materialSearchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _reloadMaterials(search: query.trim()),
    );
  }

  void retryMaterials() => _reloadMaterials(search: _materialSearch);

  Future<void> _reloadMaterials({required String search}) async {
    final seq = ++_materialRequestSeq;
    _materialSearch = search;
    _materialPage = 0;
    materials.clear();
    hasMoreMaterials.value = false;
    materialsError.value = null;
    materialsLoadMoreFailed.value = false;
    isLoadingMoreMaterials.value = false;
    isLoadingMaterials.value = true;

    try {
      final page = await _repository.fetchMaterials(
        page: 1,
        perPage: materialPageSize,
        search: search,
      );
      if (seq != _materialRequestSeq) return;

      materials.assignAll(page.items);
      _materialPage = 1;
      hasMoreMaterials.value = page.rawCount >= materialPageSize;
      _materialsLoaded = true;
    } on PrCreateException catch (e) {
      if (seq != _materialRequestSeq) return;
      materialsError.value =
          _messageFor(e, fallbackKey: 'pr_materials_load_failed');
    } catch (_) {
      if (seq != _materialRequestSeq) return;
      materialsError.value = 'pr_materials_load_failed'.tr;
    } finally {
      if (seq == _materialRequestSeq) isLoadingMaterials.value = false;
    }
  }

  /// Fetches the next page when the dropdown list is scrolled near its
  /// end (also used by the footer's manual "Retry").
  Future<void> loadMoreMaterials() async {
    if (isLoadingMaterials.value ||
        isLoadingMoreMaterials.value ||
        !hasMoreMaterials.value) {
      return;
    }

    final seq = _materialRequestSeq;
    materialsLoadMoreFailed.value = false;
    isLoadingMoreMaterials.value = true;
    try {
      final page = await _repository.fetchMaterials(
        page: _materialPage + 1,
        perPage: materialPageSize,
        search: _materialSearch,
      );
      if (seq != _materialRequestSeq) return;

      final known = materials.map((m) => m.id).toSet();
      materials.addAll(page.items.where((m) => known.add(m.id)));
      _materialPage += 1;
      hasMoreMaterials.value = page.rawCount >= materialPageSize;
    } catch (_) {
      if (seq != _materialRequestSeq) return;
      materialsLoadMoreFailed.value = true;
    } finally {
      if (seq == _materialRequestSeq) isLoadingMoreMaterials.value = false;
    }
  }

  // ======================================================================
  // Quotation attachments
  // ======================================================================

  /// Opens the file picker and uploads every selected file individually.
  Future<void> pickQuotation() async {
    if (isPickingAttachment.value) return;
    isPickingAttachment.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      var skippedDuplicate = false;
      for (final picked in result.files) {
        if (attachments.any((a) => a.name == picked.name)) {
          skippedDuplicate = true;
          continue;
        }
        final upload = PrAttachmentUpload(
          id: ++_attachmentSeq,
          file: AttachmentFile(
            name: picked.name,
            path: kIsWeb ? null : picked.path,
            bytes: kIsWeb ? picked.bytes : null,
            sizeBytes: picked.size,
          ),
        );
        attachments.add(upload);
        unawaited(_upload(upload));
      }
      if (skippedDuplicate) {
        AppSnackbar.showError('pr_attachment_duplicate'.tr);
      }
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    } finally {
      isPickingAttachment.value = false;
    }
  }

  Future<void> _upload(PrAttachmentUpload upload) async {
    upload.status.value = PrAttachmentStatus.uploading;
    upload.progress.value = 0;
    upload.errorMessage.value = null;
    upload.savedName.value = null;
    upload.cancelToken = CancelToken();

    try {
      final saved = await _repository.uploadAttachment(
        upload.file,
        cancelToken: upload.cancelToken,
        onProgress: (sent, total) {
          if (total > 0) upload.progress.value = sent / total;
        },
      );
      if (upload.removed) return;
      upload.savedName.value = saved;
      upload.progress.value = 1;
      upload.status.value = PrAttachmentStatus.uploaded;
    } on PrCreateException catch (e) {
      if (upload.removed || e.isCancelled) return;
      upload.errorMessage.value =
          _messageFor(e, fallbackKey: 'pr_attachment_upload_failed');
      upload.status.value = PrAttachmentStatus.failed;
    } catch (_) {
      if (upload.removed) return;
      upload.errorMessage.value = 'pr_attachment_upload_failed'.tr;
      upload.status.value = PrAttachmentStatus.failed;
    }
  }

  void retryUpload(PrAttachmentUpload upload) {
    if (!upload.isFailed) return;
    unawaited(_upload(upload));
  }

  /// Removes an attachment, aborting its upload if still in flight.
  void removeAttachment(PrAttachmentUpload upload) {
    upload.removed = true;
    if (upload.isUploading) upload.cancelToken.cancel();
    attachments.remove(upload);
  }

  Future<void> pickDeliveryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: deliveryDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) deliveryDate.value = picked;
  }

  // ======================================================================
  // Summary
  // ======================================================================

  /// The selected contract's margin (%) — never hard-coded; 0 until a
  /// contract is picked.
  double get administrativeExpensesPercent =>
      selectedContract.value?.margin ?? 0;

  /// Recomputed from [items] and the selected contract, so it updates as
  /// soon as either changes (read inside an `Obx`).
  PrSummary get summary => PrSummary.calculate(
        lineTotals: items.map((item) => item.total),
        marginPercent: administrativeExpensesPercent,
      );

  double get totalLines => summary.totalLines;
  double get administrativeExpenses => summary.administrativeExpenses;
  double get totalBeforeVat => summary.totalBeforeVat;
  double get vatAmount => summary.vatAmount;
  double get totalAmount => summary.totalAmount;

  // ======================================================================
  // Submit
  // ======================================================================

  /// Validates, then saves the PR. Returns true on success (the caller
  /// closes the screen); every failure is reported via a SnackBar.
  Future<bool> submit() async {
    if (isSubmitting.value) return false; // block duplicate submissions

    final validation = _validateBeforeSubmit();
    if (validation != null) {
      AppSnackbar.showError(validation);
      return false;
    }

    isSubmitting.value = true;
    try {
      final message = await _repository.savePurchaseRequest(_buildRequest());
      successMessage = (message != null && message.isNotEmpty)
          ? message
          : 'pr_submitted_success'.tr;
      resetForm();
      return true;
    } on PrCreateException catch (e) {
      AppSnackbar.showError(_messageFor(e, fallbackKey: 'pr_submit_failed'));
      return false;
    } catch (_) {
      AppSnackbar.showError('pr_submit_failed'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// First problem found, as a translated message — or null when the
  /// form is ready to submit.
  String? _validateBeforeSubmit() {
    if (selectedContract.value == null) {
      return 'pr_select_contract_required'.tr;
    }
    if (locationController.text.trim().isEmpty) {
      return 'pr_location_required'.tr;
    }
    if (workOrderController.text.trim().isEmpty) {
      return 'pr_work_order_required'.tr;
    }
    if (descriptionController.text.trim().isEmpty) {
      return 'pr_request_description_required'.tr;
    }
    if (category.value == null) {
      return 'pr_category_required'.tr;
    }
    if (purposeController.text.trim().isEmpty) {
      return 'pr_purpose_required'.tr;
    }
    if (items.isEmpty) {
      return 'pr_add_at_least_one_item'.tr;
    }
    if (attachments.any((a) => a.isUploading)) {
      return 'pr_attachment_upload_in_progress'.tr;
    }
    if (attachments.any((a) => a.isFailed)) {
      return 'pr_attachment_upload_failed_block'.tr;
    }
    // The save API needs the creator — if the stored login values are
    // missing the session is unusable, so ask the user to sign in again.
    final userId = _session.authUserId.value;
    final username = _session.authUsername.value;
    if (userId == null ||
        userId.trim().isEmpty ||
        username == null ||
        username.trim().isEmpty) {
      return 'pr_err_session_expired'.tr;
    }
    return null;
  }

  PrSaveRequestModel _buildRequest() {
    final totals = summary;
    return PrSaveRequestModel(
      userId: _requireUserId(),
      creatorName: _requireUsername(),
      // Shown on screen in Riyadh time, so the payload uses the same day.
      prDate: _apiDate(AppDateFormat.toRiyadh(requestDate)),
      contractId: selectedContract.value!.contractId,
      expectDate: _apiDate(deliveryDate.value),
      location: locationController.text.trim(),
      workOrderNo: workOrderController.text.trim(),
      purpose: purposeController.text.trim(),
      category: category.value!,
      requestDescription: descriptionController.text.trim(),
      totalBeforeVat: totals.totalBeforeVat,
      vatAmount: totals.vatAmount,
      totalAmount: totals.totalAmount,
      margin: totals.marginPercent,
      items: items.toList(),
      attachments: [
        for (final a in attachments)
          if (a.savedName.value != null) a.savedName.value!,
      ],
    );
  }

  /// `dd-MM-yyyy`, as the API expects.
  String _apiDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  /// Clears every field back to its initial state (after a successful
  /// save). The loaded contract list is kept.
  void resetForm() {
    selectedContract.value = null;
    locationController.clear();
    workOrderController.clear();
    descriptionController.clear();
    purposeController.clear();
    category.value = null;
    deliveryDate.value = DateTime.now().add(const Duration(days: 7));

    itemType.value = PurchaseRequestItemType.inventory;
    selectedMaterial.value = null;
    materialDescriptionController.clear();
    quantityController.clear();
    unitPriceController.clear();
    remarksController.clear();
    items.clear();

    for (final a in attachments) {
      a.removed = true;
      if (a.isUploading) a.cancelToken.cancel();
    }
    attachments.clear();
  }

  // ======================================================================
  // Errors
  // ======================================================================

  /// A translated, user-facing message for [e]. The server's own message
  /// wins for API-level rejections/server errors; connectivity, timeout
  /// and session problems always use the app's translated text.
  String _messageFor(PrCreateException e, {required String fallbackKey}) {
    switch (e.type) {
      case PrCreateFailure.noInternet:
        return 'pr_err_no_internet'.tr;
      case PrCreateFailure.timeout:
        return 'pr_err_timeout'.tr;
      case PrCreateFailure.unauthorized:
        return 'pr_err_session_expired'.tr;
      case PrCreateFailure.forbidden:
        return 'pr_err_forbidden'.tr;
      case PrCreateFailure.invalidResponse:
        return 'pr_err_invalid_response'.tr;
      case PrCreateFailure.server:
      case PrCreateFailure.rejected:
        final message = e.message;
        if (message != null && message.isNotEmpty) return message;
        return e.type == PrCreateFailure.server
            ? 'pr_err_server'.tr
            : fallbackKey.tr;
      case PrCreateFailure.cancelled:
      case PrCreateFailure.unknown:
        return fallbackKey.tr;
    }
  }

  @override
  void onClose() {
    _materialSearchDebounce?.cancel();
    for (final a in attachments) {
      a.removed = true;
      if (a.isUploading) a.cancelToken.cancel();
    }
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
