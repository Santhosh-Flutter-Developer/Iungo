import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/asset/presentation/controllers/scan_qr_controller.dart';
import 'package:iungo/features/asset/presentation/widgets/qr_scan_frame.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends GetView<ScanQrController> {
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward
                : Icons.arrow_back,
            color: AppColors.white,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text('scan_qr'.tr),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.torchState.value == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
                color: AppColors.white,
              ),
              onPressed: controller.toggleTorch,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller.cameraController,
            onDetect: controller.onDetect,
            errorBuilder: (context, error, child) {
              controller.onCameraError();
              return Container(
                color: AppColors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'camera_permission_denied'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.white, fontSize: 15),
                ),
              );
            },
          ),
          const IgnorePointer(child: QrScanFrame()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'scan_qr_instruction'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
          Obx(
            () => controller.isProcessing.value
                ? Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.white,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}