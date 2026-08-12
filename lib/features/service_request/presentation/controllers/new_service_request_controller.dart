import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/service_request/domain/entities/request_classification.dart';

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

  final RxList<String> attachments = <String>[].obs;

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

  void addMockAttachment() {
    attachments.add('attachment_${attachments.length + 1}.jpg');
  }

  void removeAttachment(String name) {
    attachments.remove(name);
  }

  void submit() {
    AppSnackbar.showSuccess('request_submitted'.tr);
    Get.back();
  }

  @override
  void onClose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
