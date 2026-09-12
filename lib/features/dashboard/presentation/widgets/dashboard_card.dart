import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The dashboard grid sizes every tile to fit however many
            // actions there are into one screen (no scroll), so a tile
            // can end up shorter than this card's old fixed
            // padding/icon/font sizes allowed for. Scale those
            // proportionally to the tile's actual height instead, so
            // content always fits rather than overflowing.
            final height = constraints.maxHeight;
            final iconSize = (height * 0.26).clamp(20.0, 40.0);
            final spacing = (height * 0.10).clamp(6.0, 18.0);
            final fontSize = (height * 0.09).clamp(11.0, 16.0);
            final verticalPadding = (height * 0.12).clamp(6.0, 28.0);

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: verticalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: AppColors.primary),
                  SizedBox(height: spacing),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}