import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// A [SelectField]-styled dropdown with an inline search box and a
/// clear (×) affordance — used across the "Add Purchase Request" form
/// (Contract Code, Category, Type, Material Code) per feedback on the
/// first pass, which only had a plain scrollable list.
///
/// Kept local to the Purchase Request feature (rather than extending
/// the shared `FilterSelectField`) so this doesn't change behavior for
/// the Inventory Request/Service Request/Work Order filter screens that
/// already depend on that widget's current behavior.
class PrSearchableSelectField<T> extends StatefulWidget {
  const PrSearchableSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.optionLabel,
    required this.value,
    required this.onChanged,
    this.allowClear = true,
  });

  final String label;
  final String hint;
  final List<T> options;
  final String Function(T) optionLabel;
  final T? value;

  /// Called with the picked option, or `null` when cleared.
  final ValueChanged<T?> onChanged;

  /// Whether a "×" clear affordance is shown once a value is picked.
  /// Set false for dropdowns that must always hold a value (e.g. Type).
  final bool allowClear;

  @override
  State<PrSearchableSelectField<T>> createState() =>
      _PrSearchableSelectFieldState<T>();
}

class _PrSearchableSelectFieldState<T>
    extends State<PrSearchableSelectField<T>> {
  bool _expanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _select(T option) {
    widget.onChanged(option);
    _searchController.clear();
    setState(() {
      _query = '';
      _expanded = false;
    });
  }

  void _clear() {
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.options
        : widget.options
            .where((o) => widget
                .optionLabel(o)
                .toLowerCase()
                .contains(_query.trim().toLowerCase()))
            .toList();

    final hasValue = widget.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: _toggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _expanded ? AppColors.primary : AppColors.inputBorder,
                width: _expanded ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? widget.optionLabel(widget.value as T) : widget.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue
                          ? AppColors.textDark
                          : const Color(0xFF9A9A9A),
                    ),
                  ),
                ),
                if (hasValue && widget.allowClear) ...[
                  InkWell(
                    onTap: _clear,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 18, color: AppColors.inputIcon),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.inputIcon,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: _expanded
              ? Container(
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'search'.tr,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  const BorderSide(color: AppColors.inputBorder),
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                child: Text(
                                  'no_results_found'.tr,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final option in filtered)
                                      _OptionTile(
                                        label: widget.optionLabel(option),
                                        selected: option == widget.value,
                                        onTap: () => _select(option),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
