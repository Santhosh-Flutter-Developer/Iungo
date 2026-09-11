import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iungo/core/constants/app_colors.dart';

/// Generic "Select X" full page: purple header with back/close, a search
/// box, and a scrollable list where the selected item shows a checkmark.
///
/// Search and pagination are both server-driven — this widget never
/// filters [items] itself:
/// * Typing debounces into [onSearchChanged], which the caller wires to
///   re-fetch from the picklist API with `&search=` (no client-side
///   filtering of the already-fetched page).
/// * Scrolling to the bottom fires [onLoadMore], which the caller wires
///   to fetch the next `page` and append to [items] — only while
///   [hasMore] is true and nothing is already loading.
class SelectionListPage extends StatefulWidget {
  const SelectionListPage({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onSearchChanged,
  });

  final String title;
  final String searchHint;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelected;

  /// Shows a spinner in place of the list while the first page is still
  /// being fetched from the server.
  final bool isLoading;

  /// Shows a small spinner at the bottom of the list while a subsequent
  /// page is being fetched.
  final bool isLoadingMore;

  /// Whether another page might exist — [onLoadMore] is only fired while
  /// this is true.
  final bool hasMore;

  /// Fired when the list is scrolled near the bottom. The caller is
  /// responsible for its own in-flight/hasMore guarding as well; this
  /// widget only avoids firing again while [isLoadingMore] is true.
  final VoidCallback? onLoadMore;

  /// Fired ~350ms after the user stops typing, with the trimmed query
  /// (empty string once cleared). The caller re-fetches from the API —
  /// this widget does not filter [items] locally.
  final ValueChanged<String>? onSearchChanged;

  @override
  State<SelectionListPage> createState() => _SelectionListPageState();
}

class _SelectionListPageState extends State<SelectionListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore == null) return;
    if (!widget.hasMore || widget.isLoadingMore || widget.isLoading) return;
    // Fire a little before the physical end so the next page is ready
    // just as the user reaches the bottom.
    const threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      widget.onLoadMore!();
    }
  }

  void _onSearchTextChanged(String value) {
    setState(() {}); // refresh the clear/search icon state
    _debounce?.cancel();
    if (widget.onSearchChanged == null) return;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onSearchChanged!(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchTextChanged,
                style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.inputIcon),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.inputIcon),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchTextChanged('');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: widget.isLoading && widget.items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : widget.items.isEmpty
                      ? Center(
                          child: Text(
                            'no_results_found'.tr,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount:
                              widget.items.length + (widget.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= widget.items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final item = widget.items[index];
                            final isSelected = item == widget.selectedItem;
                            return InkWell(
                              onTap: () {
                                widget.onSelected(item);
                                Get.back();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check,
                                          color: AppColors.primary, size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}