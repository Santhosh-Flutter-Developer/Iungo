import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/controllers/new_service_request_controller.dart';

/// Location picker. No maps SDK is wired up (static UI only) — the
/// background is a decorative placeholder standing in for the map tile.
class SelectLocationPage extends GetView<NewServiceRequestController> {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFE8EAED),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MapPlaceholderPainter()),
            ),
            const Align(
              alignment: Alignment(0, -0.05),
              child: Icon(
                Icons.location_on,
                size: 44,
                color: Color(0xFFE53935),
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
                _RoundIconButton(
                  icon: Icons.my_location,
                  small: true,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 6),
            Text(
              controller.address.value,
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: 'latitude'.tr,
                    value: controller.latitude.value,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'longitude'.tr,
                    value: controller.longitude.value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  controller.selectLocation(
                    address: controller.address.value,
                    latitude: controller.latitude.value,
                    longitude: controller.longitude.value,
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 40.0;
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: small ? 0 : 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Decorative stand-in for the map tile — light grey background with a
/// couple of pale "buildings" and a road line, no real map data.
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8EAED);
    canvas.drawRect(Offset.zero & size, bg);

    final road = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 14;
    canvas.drawLine(
      Offset(size.width * 0.62, 0),
      Offset(size.width * 0.68, size.height),
      road,
    );

    final building = Paint()..color = const Color(0xFFD9DCE1);
    final rects = [
      Rect.fromLTWH(size.width * 0.08, size.height * 0.10, 60, 50),
      Rect.fromLTWH(size.width * 0.22, size.height * 0.22, 70, 40),
      Rect.fromLTWH(size.width * 0.12, size.height * 0.35, 50, 60),
      Rect.fromLTWH(size.width * 0.75, size.height * 0.30, 80, 45),
      Rect.fromLTWH(size.width * 0.80, size.height * 0.45, 55, 55),
      Rect.fromLTWH(size.width * 0.30, size.height * 0.55, 65, 45),
      Rect.fromLTWH(size.width * 0.15, size.height * 0.65, 55, 50),
    ];
    for (final r in rects) {
      canvas.drawRect(r, building);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPlaceholderPainter oldDelegate) => false;
}
