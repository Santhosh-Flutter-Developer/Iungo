import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// Animated grey-bar skeleton card, shown while the list is "loading".
/// Matches the shimmer state visible at the start of the reference video.
class ServiceRequestShimmerList extends StatefulWidget {
  const ServiceRequestShimmerList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<ServiceRequestShimmerList> createState() =>
      _ServiceRequestShimmerListState();
}

class _ServiceRequestShimmerListState extends State<ServiceRequestShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _ShimmerCard(controller: _controller),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final opacity = 0.55 + 0.35 * (1 - (t - 0.5).abs() * 2);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _bar(width: 70, height: 28, opacity: opacity),
                  const Spacer(),
                  _bar(width: 110, height: 28, opacity: opacity),
                ],
              ),
              const SizedBox(height: 16),
              _bar(width: double.infinity, height: 16, opacity: opacity),
              const SizedBox(height: 8),
              _bar(width: 180, height: 16, opacity: opacity),
              const SizedBox(height: 16),
              _bar(width: double.infinity, height: 14, opacity: opacity),
              const SizedBox(height: 8),
              _bar(width: double.infinity, height: 14, opacity: opacity),
              const SizedBox(height: 14),
              _bar(width: 140, height: 36, opacity: opacity),
              const SizedBox(height: 10),
              _bar(width: double.infinity, height: 60, opacity: opacity),
            ],
          ),
        );
      },
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required double opacity,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: opacity * 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
