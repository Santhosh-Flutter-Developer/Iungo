import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({
    super.key,
    required this.isEnglishSelected,
    required this.onEnglishTap,
    required this.onArabicTap,
  });

  final bool isEnglishSelected;
  final VoidCallback onEnglishTap;
  final VoidCallback onArabicTap;

  @override
  Widget build(BuildContext context) {
    final english = _Segment(
      label: 'EN',
      selected: isEnglishSelected,
      onTap: onEnglishTap,
    );
    final arabic = _Segment(
      label: 'عربي',
      selected: !isEnglishSelected,
      onTap: onArabicTap,
    );

    // Unselected segment on the left, selected segment on the right.
    final children = isEnglishSelected ? [arabic, english] : [english, arabic];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        // clipBehavior: Clip.antiAlias,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius:selected ? BorderRadius.only(
            topRight: Radius.circular(7.0),
            bottomRight: Radius.circular(7.0),
          ):BorderRadius.only(
            topLeft: Radius.circular(7.0),
            bottomLeft: Radius.circular(7.0),
          ),
          color: selected ? AppColors.primary : AppColors.white,
        ),

        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.primary,
            // fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
