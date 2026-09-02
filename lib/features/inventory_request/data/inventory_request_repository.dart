import 'package:get/get.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_detail_remote_data_source.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_picklist_remote_data_source.dart';
import 'package:iungo/features/inventory_request/data/datasources/inventory_request_remote_data_source.dart';
import 'package:iungo/features/inventory_request/data/models/inventory_request_mapper.dart';
import 'package:iungo/features/inventory_request/domain/entities/inventory_request.dart';
import 'package:iungo/features/service_request/domain/entities/pick_list_option.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_attachment.dart';
import 'package:iungo/features/work_order/domain/entities/work_order_comment.dart';

/// Single in-memory source of truth for "Inventory Request → Awaiting
/// Client Approval".
///
/// Registered as a permanent GetxService (not tied to a page's
/// lifecycle) so the list page and search screen share the same
/// [inventoryRequests] list. Mirrors [WorkOrderRepository]/
/// [WorkOrderClosureApprovalRepository] exactly.
class InventoryRequestRepository extends GetxService {
  InventoryRequestRepository(
    this._remoteDataSource,
    this._pickListDataSource,
    this._detailDataSource,
  );

  final InventoryRequestRemoteDataSource _remoteDataSource;
  final InventoryRequestPickListRemoteDataSource _pickListDataSource;
  final InventoryRequestDetailRemoteDataSource _detailDataSource;

  final RxList<InventoryRequest> inventoryRequests = <InventoryRequest>[].obs;

  // Cached so the Filter screen's Status dropdown doesn't re-hit the
  // pickList API every time it's opened during a session.
  List<PickListOption>? _cachedStatusOptions;

  /// Fetches one page of the base (unfiltered/unsearched) "Awaiting
  /// Client Approval" list.
  Future<InventoryRequestListPageResult> fetchPage({
    required int page,
    required int perPage,
  }) {
    return _remoteDataSource.fetchAwaitingClientApproval(
      page: page,
      perPage: perPage,
    );
  }

  /// Hits the server's `quickFilter`/`search` "Awaiting Client Approval"
  /// endpoint — used once a Status/Reservation Status filter and/or a
  /// text search is active.
  Future<InventoryRequestListPageResult> fetchFiltered({
    required int page,
    required int perPage,
    Map<String, List<String>>? quickFilter,
    String? search,
  }) {
    return _remoteDataSource.fetchAwaitingClientApproval(
      page: page,
      perPage: perPage,
      quickFilter: quickFilter,
      search: search,
    );
  }

  Future<List<PickListOption>> fetchStatusOptions({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedStatusOptions != null) {
      return _cachedStatusOptions!;
    }
    final options = await _pickListDataSource.fetchStatusOptions();
    _cachedStatusOptions = options;
    return options;
  }

  /// Fetches the full record for the Detail View's Overview tab.
  Future<InventoryRequest> fetchInventoryRequestDetail(int id) async {
    final envelope = await _remoteDataSource.fetchInventoryRequestDetail(id);
    return mapInventoryRequestDetail(envelope);
  }

  // ---- Status label resolution -------------------------------------

  /// Turns the raw `moduleState`/`status` value the mapper captured
  /// (e.g. `"2355"` or `"awaitingclientapproval"`) into the
  /// human-readable label shown in the UI (e.g. "Awaiting Client
  /// Approval") — matched against the live `pickList/forms/
  /// inventoryrequest/moduleState` options (loaded via
  /// [fetchStatusOptions]) when possible, or humanized client-side as a
  /// fallback when no live pick-list match is available yet/at all.
  ///
  /// Call [fetchStatusOptions] (or [resolveStatusLabels]) first so the
  /// numeric-id match has something to work against; otherwise this
  /// falls straight through to the humanized fallback.
  String? resolveStatusLabel(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final options = _cachedStatusOptions;
    if (options != null) {
      final id = int.tryParse(value);
      if (id != null) {
        for (final option in options) {
          if (option.value == id) return option.label;
        }
      } else {
        // Some responses may already carry the slug as `value` on a
        // differently-shaped pick-list entry — match case-insensitively
        // against the label's own "slug form" as a last resort.
        for (final option in options) {
          if (_slugOf(option.label) == _slugOf(value)) return option.label;
        }
      }
    }

    return _humanizeStatusSlug(value);
  }

  /// Ensures the Status pick list is loaded, then returns [requests]
  /// with each `status` resolved to its display label — used by the
  /// list/detail controllers right after a fetch, so the raw
  /// `awaitingclientapproval`-style value is never shown on screen.
  Future<List<InventoryRequest>> resolveStatusLabels(
    List<InventoryRequest> requests,
  ) async {
    await _ensureStatusOptionsLoaded();
    return requests
        .map((r) => r.copyWith(status: resolveStatusLabel(r.status)))
        .toList();
  }

  Future<InventoryRequest> resolveStatusLabelFor(InventoryRequest request) async {
    await _ensureStatusOptionsLoaded();
    return request.copyWith(status: resolveStatusLabel(request.status));
  }

  Future<void> _ensureStatusOptionsLoaded() async {
    if (_cachedStatusOptions != null) return;
    try {
      await fetchStatusOptions();
    } catch (_) {
      // Leaves _cachedStatusOptions null — resolveStatusLabel() will
      // fall back to the humanized slug for every record instead.
    }
  }

  static String _slugOf(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Best-effort "awaitingclientapproval" → "Awaiting Client Approval"
  /// formatter for when there's no live pick-list match — greedily
  /// segments the run-together slug using a small vocabulary of common
  /// Facilio inventory/workflow status words, longest match first, so
  /// it degrades gracefully even for status values not in the list
  /// below (any unmatched run of characters is kept as its own
  /// capitalized chunk rather than dropped).
  static String _humanizeStatusSlug(String raw) {
    // Already has separators/casing — just tidy it up rather than
    // re-segment it.
    if (raw.contains(RegExp(r'[\s_\-]')) || raw != raw.toLowerCase()) {
      final withSpaces = raw
          .replaceAll(RegExp(r'[_\-]+'), ' ')
          .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m[1]} ${m[2]}',
          );
      return _titleCase(withSpaces);
    }

    final vocabulary = [
      'awaiting', 'client', 'approval', 'approved', 'approve',
      'partially', 'fully', 'reserved', 'reservation', 'issued', 'issue',
      'pending', 'rejected', 'reject', 'draft', 'submitted', 'submit',
      'closed', 'close', 'cancelled', 'cancel', 'completed', 'complete',
      'review', 'reviewed', 'progress', 'inprogress', 'open', 'onhold',
      'hold', 'request', 'requested', 'material', 'return', 'returned',
      'process', 'processing', 'new', 'active', 'inactive', 'expired',
      'scheduled', 'assigned', 'unassigned', 'confirmed', 'confirm',
    ]..sort((a, b) => b.length.compareTo(a.length));

    final words = <String>[];
    var remaining = raw;
    while (remaining.isNotEmpty) {
      final match = vocabulary.firstWhere(
        (w) => remaining.startsWith(w),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        words.add(match);
        remaining = remaining.substring(match.length);
      } else {
        // No vocabulary word starts here — peel off one character into
        // an "unmatched" fragment so we always make forward progress.
        if (words.isNotEmpty && words.last.startsWith('\u0000')) {
          words[words.length - 1] = words.last + remaining[0];
        } else {
          words.add('\u0000${remaining[0]}');
        }
        remaining = remaining.substring(1);
      }
    }

    final cleaned = words.map((w) => w.replaceAll('\u0000', '')).where(
          (w) => w.isNotEmpty,
        );
    if (cleaned.isEmpty) return _titleCase(raw);
    return cleaned.map(_capitalize).join(' ');
  }

  static String _titleCase(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map(_capitalize)
      .join(' ');

  static String _capitalize(String word) =>
      word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';

  // ---- Detail View: Notes ----------------------------------------------

  Future<List<WorkOrderComment>> fetchNotes(int inventoryRequestId) {
    return _detailDataSource.fetchNotes(inventoryRequestId);
  }

  // ---- Detail View: Attachments -----------------------------------------

  Future<List<WorkOrderAttachment>> fetchAttachments(int inventoryRequestId) {
    return _detailDataSource.fetchAttachments(inventoryRequestId);
  }

  /// Replaces the whole list with a freshly-fetched first page (initial
  /// load / pull-to-refresh).
  void replaceWithPage(List<InventoryRequest> page) {
    inventoryRequests.assignAll(page);
  }

  /// Appends a subsequent page, skipping any ids already present (guards
  /// against duplicate cards if a record shifts pages between requests).
  void appendPage(List<InventoryRequest> page) {
    final existingIds = inventoryRequests.map((r) => r.id).toSet();
    final newOnes = page.where((r) => !existingIds.contains(r.id));
    inventoryRequests.addAll(newOnes);
  }
}
