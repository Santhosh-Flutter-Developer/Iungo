import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/data/service_request_repository.dart';
import 'package:iungo/features/service_request/domain/entities/attachment_file.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';
import 'package:iungo/features/service_request/presentation/bindings/service_request_list_binding.dart';

/// Holds all state for the (static/UI-only) "New Service Request" form.
/// Nothing here talks to a real API — every list and default value is
/// mocked so the screen matches the reference design pixel-for-pixel.
class NewServiceRequestController extends GetxController {
  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();

  final Rxn<RequestClassification> classification =
      Rxn<RequestClassification>();
  final RxBool isClassificationExpanded = false.obs;

  final RxString selectedSite = 'Diriyah At Turaif'.obs;
  final Rxn<String> selectedBuilding = Rxn<String>();
  final Rxn<String> selectedAsset = Rxn<String>();

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

  static const List<String> sites = ['Diriyah At Turaif'];

  static const List<String> buildings = [
    'Public Toilets 4',
    'Public Toilets 3',
    'Public Toilets 2',
    'Public Toilets 1',
    'Cluster3-10',
    'Archaeological Excavation',
    'Al-Turaif Bridge',
    'Military Museum',
    'Ardah Dance House',
    'ZONE20-Roads & Open Area',
  ];

  /// Mocked asset list — generated from the building name so every
  /// building has a plausible-looking asset code list.
  List<String> assetsFor(String building) {
    final match = RegExp(r'\d+').firstMatch(building);
    final prefix = 'PT${match?.group(0) ?? '1'}';
    final assets = <String>[
      for (var i = 1; i <= 7; i++)
        '$prefix/GF/RM1/MECH/TOFIX/${i.toString().padLeft(3, '0')}',
    ];
    if (prefix == 'PT1') {
      assets.addAll([
        for (var i = 1; i <= 3; i++)
          '$prefix/GF/RM1/MECH/WBASIN/${i.toString().padLeft(3, '0')}',
      ]);
    } else {
      assets.addAll([
        for (var i = 8; i <= 10; i++)
          '$prefix/GF/RM1/MECH/TOFIX/${i.toString().padLeft(3, '0')}',
      ]);
    }
    return assets;
  }

  void toggleClassificationExpanded() {
    isClassificationExpanded.toggle();
  }

  void selectClassification(RequestClassification value) {
    classification.value = value;
    isClassificationExpanded.value = false;
  }

  void selectSite(String value) {
    selectedSite.value = value;
  }

  void selectBuilding(String value) {
    selectedBuilding.value = value;
    selectedAsset.value = null;
  }

  void selectAsset(String value) {
    selectedAsset.value = value;
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

  void submit() {
    ServiceRequestListBinding.ensureRepositoryRegistered();
    final repository = Get.find<ServiceRequestRepository>();

    final subject = subjectController.text.trim();
    repository.addFromSubmission(
      subject: subject.isEmpty ? 'new_service_request'.tr : subject,
      description: descriptionController.text.trim(),
      site: selectedSite.value,
    );

    AppSnackbar.showSuccess('request_submitted'.tr);
    Get.back();
  }

  @override
  void onClose() {
    subjectController.dispose();
    descriptionController.dispose();
    mapController?.dispose();
    super.onClose();
  }
}
