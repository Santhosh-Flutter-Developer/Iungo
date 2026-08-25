import 'package:get/get.dart';
import 'package:iungo/core/widgets/app_snackbar.dart';
import 'package:iungo/features/asset/presentation/bindings/asset_detail_binding.dart';
import 'package:iungo/features/asset/presentation/pages/asset_detail_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Drives the Scan QR camera screen: owns the [MobileScannerController],
/// debounces repeated detections of the same frame, and hands the first
/// successfully-decoded value off to Asset Detail.
class ScanQrController extends GetxController {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    torchEnabled: false,
  );

  /// True while a decoded value is being resolved into navigation — set
  /// as soon as the first valid barcode comes in, so any further frames
  /// (or a second raw detection from the same code) are ignored instead
  /// of pushing Asset Detail twice.
  final RxBool isProcessing = false.obs;

  final Rx<TorchState> torchState = TorchState.off.obs;

  @override
  void onInit() {
    super.onInit();
    cameraController.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    torchState.value = cameraController.value.torchState;
  }

  void toggleTorch() => cameraController.toggleTorch();

  void onDetect(BarcodeCapture capture) {
    if (isProcessing.value) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((value) => value != null && value.trim().isNotEmpty,
            orElse: () => null);
    if (rawValue == null) return;

    isProcessing.value = true;
    cameraController.stop();

    Get.off(
      () => const AssetDetailPage(),
      binding: AssetDetailBinding(scannedValue: rawValue.trim()),
    );
  }

  void onCameraError() {
    AppSnackbar.showError('camera_permission_denied'.tr);
  }

  @override
  void onClose() {
    cameraController.removeListener(_onControllerStateChanged);
    cameraController.dispose();
    super.onClose();
  }
}