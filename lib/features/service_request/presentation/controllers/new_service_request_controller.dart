import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/data/datasources/service_request_exceptions.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';

/// Holds all state for the "New Service Request" form and now talks to
/// the real Site/Building/Asset pick-list APIs and the create API
/// (confirmed via the picklist/attachment API reference doc + Postman
/// capture of a live create call).
class NewServiceRequestController extends GetxController {
  NewServiceRequestController(
    this._repository,
    this._session, {
    int? prefillSiteId,
    String? prefillSiteName,
    int? prefillAssetId,
    String? prefillAssetLabel,
  })  : _prefillSiteId = prefillSiteId,
        _prefillSiteName = prefillSiteName,
        _prefillAssetId = prefillAssetId,
        _prefillAssetLabel = prefillAssetLabel;

  final ServiceRequestRepository _repository;
  final SessionService _session;

  /// Set when this form was opened from Asset Detail's "create service
  /// request for this asset" action (reached via Scan QR) — the Site
  /// and Asset fields are pre-selected from those values in [onInit],
  /// before the Site pick-list loads, so the single-site auto-select
  /// there doesn't clobber them.
  final int? _prefillSiteId;
  final String? _prefillSiteName;
  final int? _prefillAssetId;
  final String? _prefillAssetLabel;

  /// The form's own id (confirmed via Postman capture) — sent as both
  /// `formId` and `actionFormId` on create.
  static const _formId = 6785;

  /// Matches [ServiceRequestListController]'s own page size, so the
  /// post-submit refetch loads the same first page the list would.
  static const _listPerPage = 10;

  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();

  final Rxn<RequestClassification> classification =
      Rxn<RequestClassification>();
  final RxBool isClassificationExpanded = false.obs;

  // --- Site / Building / Asset ------------------------------------------
  //
  // Each field keeps the option list from the pickList API, the picked
  // label (what's shown on the form), and the picked id (what's sent on
  // create) side by side — [SelectionListPage] only ever deals in labels,
  // so the id is resolved by matching against the last-fetched list.

  final RxList<PickListOption> siteOptions = <PickListOption>[].obs;
  final RxList<PickListOption> buildingOptions = <PickListOption>[].obs;
  final RxList<PickListOption> assetOptions = <PickListOption>[].obs;

  final RxBool isLoadingSites = false.obs;
  final RxBool isLoadingBuildings = false.obs;
  final RxBool isLoadingAssets = false.obs;

  final Rxn<String> selectedSite = Rxn<String>();
  final Rxn<String> selectedBuilding = Rxn<String>();
  final Rxn<String> selectedAsset = Rxn<String>();

  int? _selectedSiteId;
  int? _selectedBuildingId;
  int? _selectedAssetId;

  final RxString address =
      '2nd Street, Madurai, beside Muthu Patti, Tamil Nadu, IN, - 625003'.obs;
  final RxString latitude = '9.888988'.obs;
  final RxString longitude = '78.095726'.obs;

  /// Live Google Map state for [SelectLocationPage]. The map keeps a pin
  /// fixed at screen-centre and the camera position becomes the picked
  /// coordinate; [address]/[latitude]/[longitude] above only get written
  /// back to the form once the user taps Submit there.
  GoogleMapController? mapController;
  final Rxn<LatLng> mapPosition = Rxn<LatLng>();
  final RxBool isResolvingAddress = false.obs;
  final RxBool isLocatingDevice = false.obs;

  final RxList<AttachmentFile> attachments = <AttachmentFile>[].obs;
  final RxBool isPickingAttachment = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _applyPrefillIfAny();
    _loadSiteOptions();
  }

  void _applyPrefillIfAny() {
    final siteId = _prefillSiteId;
    final siteName = _prefillSiteName;
    if (siteId != null && siteName != null && siteName.trim().isNotEmpty) {
      selectedSite.value = siteName;
      _selectedSiteId = siteId;
    }
    final assetId = _prefillAssetId;
    final assetLabel = _prefillAssetLabel;
    if (assetId != null && assetLabel != null && assetLabel.trim().isNotEmpty) {
      selectedAsset.value = assetLabel;
      _selectedAssetId = assetId;
    }
  }

  Future<void> _loadSiteOptions({String? search}) async {
    isLoadingSites.value = true;
    try {
      final options = await _repository.fetchSiteOptions(search: search);
      siteOptions.assignAll(options);
      // Auto-select when there's exactly one site (matches the
      // single-site org shown in the reference screenshots) and nothing
      // is picked yet.
      if (search == null && selectedSite.value == null && options.length == 1) {
        _applySite(options.first);
      }
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isLoadingSites.value = false;
    }
  }

  Future<void> _loadBuildingOptions({String? search}) async {
    final siteId = _selectedSiteId;
    if (siteId == null) return;
    isLoadingBuildings.value = true;
    try {
      final options = await _repository.fetchBuildingOptions(
        siteId: siteId,
        search: search,
      );
      buildingOptions.assignAll(options);
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isLoadingBuildings.value = false;
    }
  }

  Future<void> _loadAssetOptions({String? search}) async {
    final siteId = _selectedSiteId;
    if (siteId == null) return;
    isLoadingAssets.value = true;
    try {
      final options = await _repository.fetchAssetOptions(
        siteId: siteId,
        search: search,
      );
      assetOptions.assignAll(options);
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isLoadingAssets.value = false;
    }
  }

  /// Called when the Site selector is opened, so its list is fresh.
  void onOpenSitePicker() => _loadSiteOptions();

  /// Called when the Building selector is opened.
  void onOpenBuildingPicker() => _loadBuildingOptions();

  /// Called when the Asset selector is opened.
  void onOpenAssetPicker() => _loadAssetOptions();

  void toggleClassificationExpanded() {
    isClassificationExpanded.toggle();
  }

  void selectClassification(RequestClassification value) {
    classification.value = value;
    isClassificationExpanded.value = false;
  }

  void _applySite(PickListOption option) {
    selectedSite.value = option.label;
    _selectedSiteId = option.value;
    // Site changed — Building/Asset selections no longer apply.
    selectedBuilding.value = null;
    selectedAsset.value = null;
    _selectedBuildingId = null;
    _selectedAssetId = null;
    buildingOptions.clear();
    assetOptions.clear();
  }

  void selectSite(String label) {
    final match = siteOptions.firstWhereOrNull((o) => o.label == label);
    if (match != null) _applySite(match);
  }

  void selectBuilding(String label) {
    final match = buildingOptions.firstWhereOrNull((o) => o.label == label);
    if (match == null) return;
    selectedBuilding.value = match.label;
    _selectedBuildingId = match.value;
    // Switching the building discards the previous asset pick.
    selectedAsset.value = null;
    _selectedAssetId = null;
  }

  void selectAsset(String label) {
    final match = assetOptions.firstWhereOrNull((o) => o.label == label);
    if (match == null) return;
    selectedAsset.value = match.label;
    _selectedAssetId = match.value;
  }

  /// Drops the current Asset selection (picked or prefilled from Asset
  /// Detail's "create request for this asset" action) — the field's
  /// "X" button.
  void clearAsset() {
    selectedAsset.value = null;
    _selectedAssetId = null;
  }

  void selectLocation({
    required String address,
    required String latitude,
    required String longitude,
  }) {
    this.address.value = address;
    this.latitude.value = latitude;
    this.longitude.value = longitude;
  }

  /// Starting camera position for the map picker — parsed from whatever
  /// address/lat/lng the form already holds, falling back to Madurai.
  LatLng get initialMapPosition {
    final lat = double.tryParse(latitude.value) ?? 9.888988;
    final lng = double.tryParse(longitude.value) ?? 78.095726;
    return LatLng(lat, lng);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapPosition.value ??= initialMapPosition;
  }

  /// Called on every camera frame while dragging — cheap, no network call.
  void onMapCameraMove(CameraPosition position) {
    mapPosition.value = position.target;
  }

  /// Called once the camera settles — this is when we resolve the address.
  Future<void> onMapCameraIdle() async {
    final position = mapPosition.value;
    if (position == null) return;
    await _reverseGeocode(position);
  }

  Future<void> _reverseGeocode(LatLng position) async {
    isResolvingAddress.value = true;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
          p.postalCode,
        ].where((part) => part != null && part.trim().isNotEmpty).toSet();
        if (parts.isNotEmpty) {
          address.value = parts.join(', ');
        }
      }
    } catch (_) {
      // Reverse geocoding can fail offline or if no result is found —
      // keep whatever address was already shown rather than blanking it.
    } finally {
      isResolvingAddress.value = false;
    }
  }

  /// Moves the map to the device's current GPS location, requesting
  /// permission first if needed.
  Future<void> useCurrentLocation() async {
    if (isLocatingDevice.value) return;
    isLocatingDevice.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackbar.showError('location_service_disabled'.tr);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackbar.showError('location_permission_denied'.tr);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      mapPosition.value = latLng;
      await mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      await _reverseGeocode(latLng);
    } catch (_) {
      AppSnackbar.showError('location_fetch_failed'.tr);
    } finally {
      isLocatingDevice.value = false;
    }
  }

  /// Opens the device camera and appends the captured photo, if any.
  Future<void> pickFromCamera() async {
    if (isPickingAttachment.value) return;
    isPickingAttachment.value = true;
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (photo == null) return;
      final bytes = kIsWeb ? await photo.readAsBytes() : null;
      attachments.add(AttachmentFile(
        name: photo.name,
        path: kIsWeb ? null : photo.path,
        bytes: bytes,
      ));
    } catch (_) {
      AppSnackbar.showError('attachment_camera_failed'.tr);
    } finally {
      isPickingAttachment.value = false;
    }
  }

  /// Opens the system file/photo picker — any file type, images included —
  /// and appends whatever the user selects (multiple selection allowed).
  Future<void> pickFileOrImage() async {
    if (isPickingAttachment.value) return;
    isPickingAttachment.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null) return;
      for (final file in result.files) {
        attachments.add(AttachmentFile(
          name: file.name,
          path: kIsWeb ? null : file.path,
          bytes: kIsWeb ? file.bytes : null,
        ));
      }
    } catch (_) {
      AppSnackbar.showError('attachment_pick_failed'.tr);
    } finally {
      isPickingAttachment.value = false;
    }
  }

  void removeAttachment(AttachmentFile attachment) {
    attachments.remove(attachment);
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    final subject = subjectController.text.trim();
    if (subject.isEmpty) {
      AppSnackbar.showError('subject_required'.tr);
      return;
    }
    final siteId = _selectedSiteId;
    if (siteId == null) {
      AppSnackbar.showError('site_required'.tr);
      return;
    }

    isSubmitting.value = true;
    try {
      ServiceRequestListBinding.ensureRepositoryRegistered();

      final requesterId = int.tryParse(_session.userId.value ?? '');
      final resourceId = _selectedAssetId ?? _selectedBuildingId;

      await _repository.submitNewServiceRequest(
        subject: subject,
        description: descriptionController.text.trim(),
        siteId: siteId,
        siteName: selectedSite.value ?? '',
        resourceId: resourceId,
        buildingName: selectedBuilding.value,
        locationFreeText: address.value,
        requesterId: requesterId,
        requesterName: _session.userName.value,
        requesterEmail: _session.userEmail.value,
        classification: classification.value,
        attachments: attachments,
        formId: _formId,
      );

      // Re-fetch "My Service Requests" page 1 from the server (rather
      // than relying solely on the locally-inserted ticket) so the list
      // reflects the record exactly as the server created it — then
      // navigate. Best-effort: if this refetch fails, the locally
      // inserted ticket is still there, and the list page's own onInit
      // will retry the fetch anyway.
      try {
        final result = await _repository.fetchPage(
          page: 1,
          perPage: _listPerPage,
        );
        _repository.replaceWithPage(result.tickets);
      } catch (_) {
        // Ignore — see comment above.
      }

      AppSnackbar.showSuccess('request_submitted'.tr);
      // Go straight to "My Service Requests" — replaces this form
      // (rather than pushing on top of it) so the person can't navigate
      // "back" into an already-submitted form.
      Get.offNamed(AppRoutes.serviceRequestList);
    } on ServiceRequestException catch (e) {
      AppSnackbar.showError(
        e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr,
      );
    } catch (_) {
      AppSnackbar.showError('something_went_wrong'.tr);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    subjectController.dispose();
    descriptionController.dispose();
    mapController?.dispose();
    super.onClose();
  }
}