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
///
/// With only the required arguments it is a plain, locally-filtered
/// dropdown. The optional "remote data" arguments below let a list that
/// comes from an API (Contract Code, Material Code) show loading /
/// error / empty states, search on the server, and load more pages as
/// the user scrolls.
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
    this.isLoading = false,
    this.errorText,
    this.onRetry,
    this.emptyText,
    this.onOpened,
    this.onSearchChanged,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
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

  // ---- Remote-data options (all optional) ----------------------------

  /// The options are still being fetched — shows a spinner (in the field
  /// and, while [options] is empty, in the open list).
  final bool isLoading;

  /// Set when fetching failed and [options] is empty — shown in the open
  /// list, with a Retry action when [onRetry] is given.
  final String? errorText;
  final VoidCallback? onRetry;

  /// Replaces the default "No Results Found" text when the list is empty.
  final String? emptyText;

  /// Fired each time the dropdown is opened (lets the owner lazily load
  /// its first page).
  final VoidCallback? onOpened;

  /// When non-null the search box is applied on the server: typing
  /// reports the query here instead of filtering [options] locally.
  final ValueChanged<String>? onSearchChanged;

  /// Non-null while more pages exist. Called when the list is scrolled
  /// near its end, and by the footer's Retry after [loadMoreFailed].
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  @override
  State<PrSearchableSelectField<T>> createState() =>
      _PrSearchableSelectFieldState<T>();
}

class _PrSearchableSelectFieldState<T>
    extends State<PrSearchableSelectField<T>> {
  bool _expanded = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Asks the owner for the next page once the list is near its end.
  void _onScroll() {
    final loadMore = widget.onLoadMore;
    if (loadMore == null || widget.isLoadingMore || widget.loadMoreFailed) {
      return;
    }
    if (_scrollController.position.extentAfter < 120) loadMore();
  }

  void _toggle() {
    final opening = !_expanded;
    setState(() {
      _expanded = opening;
      if (!_expanded) {
        _searchController.clear();
        _query = '';
      }
    });
    if (opening) widget.onOpened?.call();
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
    final filtered = (widget.onSearchChanged != null || _query.trim().isEmpty)
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
                if (widget.isLoading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                          onChanged: (v) {
                            setState(() => _query = v);
                            widget.onSearchChanged?.call(v);
                          },
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
                        child: _buildBody(filtered),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildBody(List<T> filtered) {
    if (filtered.isEmpty) {
      if (widget.isLoading) {
        return const _StatusRow(child: _Spinner());
      }
      final error = widget.errorText;
      if (error != null) {
        return _StatusRow(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.attachmentDeleteText,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text('retry'.tr),
                ),
              ],
            ],
          ),
        );
      }
      return _StatusRow(
        child: Text(
          // The custom empty text describes "nothing to choose from"; a
          // search that just matches nothing keeps the standard message.
          (widget.options.isEmpty ? widget.emptyText : null) ??
              'no_results_found'.tr,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }

    final showFooter = widget.isLoadingMore || widget.loadMoreFailed;
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: filtered.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filtered.length) {
          return widget.loadMoreFailed
              ? InkWell(
                  onTap: widget.onLoadMore,
                  child: _StatusRow(
                    child: Text(
                      'retry'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : const _StatusRow(child: _Spinner());
        }
        final option = filtered[index];
        return _OptionTile(
          label: widget.optionLabel(option),
          selected: option == widget.value,
          onTap: () => _select(option),
        );
      },
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      alignment: Alignment.center,
      child: child,
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
