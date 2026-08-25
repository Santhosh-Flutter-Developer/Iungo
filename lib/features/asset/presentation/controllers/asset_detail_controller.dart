import 'package:get/get.dart';
import 'package:iungo/features/asset/data/asset_repository.dart';
import 'package:iungo/features/asset/data/datasources/asset_exceptions.dart';
import 'package:iungo/features/asset/domain/entities/asset.dart';
import 'package:iungo/features/service_request/presentation/bindings/new_service_request_binding.dart';
import 'package:iungo/features/service_request/presentation/pages/new_service_request_page.dart';

/// Loads and holds the asset shown on the "Asset Detail" screen, reached
/// after a successful QR scan — [scannedValue] is whatever the QR code
/// decoded to (a plain asset id, or a code/URL the repository reduces
/// to one).
class AssetDetailController extends GetxController {
  AssetDetailController(this._repository, this.scannedValue);

  final AssetRepository _repository;
  final String scannedValue;

  final Rxn<Asset> asset = Rxn<Asset>();
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      asset.value = await _repository.fetchAssetByIdentifier(scannedValue);
    } on AssetException catch (e) {
      errorMessage.value =
          e.message.trim().isNotEmpty ? e.message : 'something_went_wrong'.tr;
    } catch (_) {
      errorMessage.value = 'something_went_wrong'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retry() => _loadAsset();

  /// Opens "New Service Request" pre-filled with this asset's Site and
  /// Asset fields already selected — the flow shown in the reference
  /// video (tapping the Asset Detail AppBar's document icon).
  void createServiceRequestForAsset() {
    final current = asset.value;
    if (current == null) return;
    Get.to(
      () => const NewServiceRequestPage(),
      binding: NewServiceRequestBinding(
        prefillSiteId: current.siteId,
        prefillSiteName: current.siteName,
        prefillAssetId: current.id,
        prefillAssetLabel: current.name,
      ),
    );
  }
}