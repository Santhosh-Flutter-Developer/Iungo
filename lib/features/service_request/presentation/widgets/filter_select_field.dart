import 'package:flutter/material.dart';
import 'package:iungo/core/constants/app_colors.dart';
import 'package:iungo/features/service_request/presentation/widgets/select_field.dart';

/// Generic version of the "New Service Request" [ClassificationDropdown]
/// pattern: a [SelectField] that expands an inline options list directly
/// below it. Used for Service Request Type / Status / Priority on the
/// filter screen.
class FilterSelectField<T> extends StatefulWidget {
  const FilterSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.optionLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<T> options;
  final String Function(T) optionLabel;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  State<FilterSelectField<T>> createState() => _FilterSelectFieldState<T>();
}

class _FilterSelectFieldState<T> extends State<FilterSelectField<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectField(
          label: widget.label,
          hint: widget.hint,
          value: widget.value == null ? null : widget.optionLabel(widget.value as T),
          isExpanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: _expanded
              ? Container(
                  margin: const EdgeInsets.only(top: 2),
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in widget.options)
                          _OptionTile(
                            label: widget.optionLabel(option),
                            selected: option == widget.value,
                            onTap: () {
                              widget.onChanged(option);
                              setState(() => _expanded = false);
                            },
                          ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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
        width: double.infinity,
        color: selected
            ? AppColors.drawerSelectedBackground
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
