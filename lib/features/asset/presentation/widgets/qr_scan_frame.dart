import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// The dimmed-background + bracket-cornered square + moving scan line
/// drawn on top of the camera preview on the Scan QR screen.
class QrScanFrame extends StatefulWidget {
  const QrScanFrame({super.key, this.cutoutSize = 260});

  final double cutoutSize;

  @override
  State<QrScanFrame> createState() => _QrScanFrameState();
}

class _QrScanFrameState extends State<QrScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = widget.cutoutSize;
        final cutoutRect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: size,
          height: size,
        );

        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScrimPainter(cutoutRect: cutoutRect),
            ),
            Positioned.fromRect(
              rect: cutoutRect,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CornersAndScanLinePainter(
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.cutoutRect});

  final Rect cutoutRect;

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPaint = Paint()..color = Colors.black.withOpacity(0.55);

    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)));

    final scrim = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(scrim, scrimPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)),
      Paint()
        ..color = AppColors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) =>
      oldDelegate.cutoutRect != cutoutRect;
}

class _CornersAndScanLinePainter extends CustomPainter {
  _CornersAndScanLinePainter({required this.progress});

  final double progress;

  static const _cornerLength = 28.0;
  static const _strokeWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(_cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, _cornerLength), cornerPaint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-_cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, _cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(_cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -_cornerLength), cornerPaint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-_cornerLength, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -_cornerLength), cornerPaint);

    // Scan line sweeping top-to-bottom.
    final lineY = size.height * progress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0),
          AppColors.primary,
          AppColors.primary.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, lineY - 1, size.width, 2));
    canvas.drawRect(Rect.fromLTWH(8, lineY - 1, size.width - 16, 2), linePaint);
  }

  @override
  bool shouldRepaint(covariant _CornersAndScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}