import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';

class SelectLocationPage extends GetView<NewServiceRequestController> {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.initialMapPosition,
                zoom: 16,
              ),
              onMapCreated: controller.onMapCreated,
              onCameraMove: controller.onMapCameraMove,
              onCameraIdle: () => controller.onMapCameraIdle(),
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          // Pin fixed at screen-centre — the map moves underneath it, not
          // the other way around, so its tip always marks the picked point.
          const IgnorePointer(
            child: Align(
              alignment: Alignment(0, -0.05),
              child: Icon(
                Icons.location_on,
                size: 44,
                color: Color(0xFFE53935),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _RoundIconButton(
                  icon: isRtl ? Icons.arrow_forward : Icons.arrow_back,
                  onTap: () => Get.back(),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _LocationCard(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.controller});

  final NewServiceRequestController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: 320,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                
                
                Expanded(
                  child: Text(
                    'select_location'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => _RoundIconButton(
                    icon: Icons.my_location,
                    small: true,
                    loading: controller.isLocatingDevice.value,
                    onTap: controller.useCurrentLocation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.headingBlueGrey),
                const SizedBox(width: 6),
                Text(
                  'address'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.headingBlueGrey,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => controller.isResolvingAddress.value
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Obx(
              () => Text(
                controller.address.value,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 14),
            Obx(
              () {
                final position =
                    controller.mapPosition.value ?? controller.initialMapPosition;
                return Row(
                  children: [
                    Expanded(
                      child: _InfoColumn(
                        label: 'latitude'.tr,
                        value: position.latitude.toStringAsFixed(6),
                      ),
                    ),
                    Expanded(
                      child: _InfoColumn(
                        label: 'longitude'.tr,
                        value: position.longitude.toStringAsFixed(6),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final position =
                      controller.mapPosition.value ?? controller.initialMapPosition;
                  controller.selectLocation(
                    address: controller.address.value,
                    latitude: position.latitude.toStringAsFixed(6),
                    longitude: position.longitude.toStringAsFixed(6),
                  );
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'submit'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

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
            fontSize: 14,
            color: AppColors.headingBlueGrey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.small = false,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool small;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 40.0;
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: small ? 0 : 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}
