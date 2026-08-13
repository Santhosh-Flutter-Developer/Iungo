import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// A bordered, tappable "field" that looks like a text field but opens a
/// picker (either an inline dropdown or a new page) instead of a keyboard.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
    this.isExpanded = false,
  });

  final String label;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  /// When this field controls an inline dropdown (e.g. Classification),
  /// pass whether it is currently open so the border/arrow can react.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isExpanded ? AppColors.primary : AppColors.inputBorder,
                width: isExpanded ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: value == null
                          ? const Color(0xFF9A9A9A)
                          : AppColors.textDark,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.inputIcon,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
