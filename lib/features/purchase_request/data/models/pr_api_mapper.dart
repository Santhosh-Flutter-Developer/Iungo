import 'package:iungo/core/constants/app_urls.dart';
import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_attachment.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_filter_options.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_list_page.dart';
import 'package:iungo/features/purchase_request/domain/entities/pr_pipeline_stage.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_item.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Parses the Purchase Request list API response
/// (`{"code": 200, "data": {"records": [...], ...}}`) into typed
/// entities. Every field is read defensively — PHP can send numbers as
/// strings, omit a key, or send `null`/`[]` for an empty value — so one
/// malformed record is skipped instead of failing the whole page.
class PrApiMapper {
  PrApiMapper._();

  /// [requestedPage]/[requestedLimit] are only used as fallbacks when
  /// the response leaves `page_number` / `page_limit` out.
  static PrListPage listPage(
    Map<String, dynamic> body, {
    required int requestedPage,
    required int requestedLimit,
  }) {
    final data = body['data'];
    if (data is! Map) {
      throw const PrCreateException(PrCreateFailure.invalidResponse);
    }
    final map = Map<String, dynamic>.from(data);

    final rawRecords = map['records'];
    final records = <PurchaseRequest>[];
    if (rawRecords is List) {
      for (final row in rawRecords) {
        if (row is! Map) continue;
        final parsed = record(Map<String, dynamic>.from(row));
        if (parsed != null) records.add(parsed);
      }
    }

    final pageNumber = _int(map['page_number']) ?? requestedPage;
    final pageLimit = _int(map['page_limit']) ?? requestedLimit;
    final totalRecords = _int(map['total_records']) ?? records.length;
    final totalPages = _int(map['total_pages']) ??
        (pageLimit > 0 ? (totalRecords / pageLimit).ceil() : 1);

    return PrListPage(
      records: records,
      pageNumber: pageNumber,
      pageLimit: pageLimit,
      totalRecords: totalRecords,
      totalPages: totalPages,
      startRecord: _int(map['start_record']),
      endRecord: _int(map['end_record']),
      addPurchaseRequest: _flag(map['add_purchase_request']),
      createdStatusCount: _int(map['created_status_count']),
      completedStatusCount: _int(map['completed_status_count']),
      rejectedStatusCount: _int(map['rejected_status_count']),
      filterOptions: filterOptions(map['filter_options']),
    );
  }

  /// One `records[]` entry. Returns null when the record has no usable
  /// `id` (it could never be approved/rejected or opened reliably).
  static PurchaseRequest? record(Map<String, dynamic> json) {
    final id = _int(json['id']);
    if (id == null) return null;

    final contractName = _str(json['contract_name']);
    final contract = _str(json['contract']);
    final statusText = _str(json['status']);
    final moduleState = _str(json['moduleState']);
    final nextApprovalRaw = _nullableStr(json['next_approval']);

    return PurchaseRequest(
      id: id,
      prNumber: _str(json['pr_number']),
      requestDate: parseApiDate(json['pr_date']),
      contractId: _str(json['contract_id']),
      contractName: contractName,
      contract: contract.isNotEmpty ? contract : contractName,
      location: _str(json['location']),
      workOrderNo: _str(json['work_order_no']),
      requestDescription: _str(json['request_description']),
      deliveryDate: parseApiDate(json['expect_date']),
      category: _str(json['category']),
      purpose: _str(json['purpose']),
      creatorId: _str(json['creator']),
      createdBy: _str(json['created_by']),
      status: statusFrom(statusText, moduleState),
      statusText: statusText,
      moduleState: moduleState,
      nextApprovalRaw: nextApprovalRaw,
      nextApprovalName: cleanNextApproval(nextApprovalRaw),
      margin: _double(json['margin']) ?? 0,
      totalBeforeVat: _double(json['total_before_vat']) ?? 0,
      vatAmount: _double(json['vat_amount']) ?? 0,
      totalAmount: _double(json['total_amount']) ?? 0,
      items: _items(json['items']),
      attachments: _attachments(json['attachments']),
      deliveryNotes: _attachments(json['delivery_notes']),
      invoices: _attachments(json['invoices']),
      pipeline: _pipeline(json['pipeline']),
      pdfPath: _pdfUrl(json['pdf_path']),
      fileUpload: _flag(json['file_upload']),
    );
  }

  // ---- status ----------------------------------------------------------

  /// Maps the API's `status` text ("Pending" / "Approved" / "Rejected")
  /// to the badge state, using `moduleState` (`O` / `C` / `R`) when the
  /// text isn't one of those.
  static PurchaseRequestStatus statusFrom(
    String statusText,
    String moduleState,
  ) {
    final text = statusText.trim().toLowerCase();
    if (text.startsWith('reject')) return PurchaseRequestStatus.rejected;
    if (text.startsWith('approv') || text.startsWith('complet')) {
      return PurchaseRequestStatus.approved;
    }
    if (text.startsWith('pend') || text.startsWith('wait')) {
      return PurchaseRequestStatus.pending;
    }

    switch (moduleState.trim().toUpperCase()) {
      case 'R':
        return PurchaseRequestStatus.rejected;
      case 'C':
        return PurchaseRequestStatus.approved;
      default:
        return PurchaseRequestStatus.pending;
    }
  }

  /// "Gladson Aby (Pending)" -> "Gladson Aby". Returns null when nobody
  /// is pending ("", "--", "-", "null").
  static String? cleanNextApproval(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty ||
        cleaned == '--' ||
        cleaned == '-' ||
        cleaned.toLowerCase() == 'null') {
      return null;
    }
    return cleaned;
  }

  // ---- items / attachments / pipeline ----------------------------------

  static List<PurchaseRequestItem> _items(dynamic raw) {
    if (raw is! List) return const [];
    final result = <PurchaseRequestItem>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final json = Map<String, dynamic>.from(row);

      // Rows the API flags as deleted are not part of the request.
      final deleted = _int(json['deleted']);
      if (deleted != null && deleted != 0) continue;

      final materialType = _nullableStr(json['material_type']);
      final code = _nullableStr(json['material_code']);
      result.add(
        PurchaseRequestItem(
          id: _int(json['id']),
          sno: _int(json['sno']),
          type: _itemType(materialType),
          materialTypeLabel: materialType,
          materialCode: code,
          materialId: _int(json['fac_id']),
          materialDescription: _str(json['material_desc']),
          remarks: _str(json['remarks']),
          quantity: _double(json['quantity']) ?? 0,
          unitPrice: _double(json['unit_price']) ?? 0,
          apiTotal: _double(json['total']),
        ),
      );
    }
    return result;
  }

  static PurchaseRequestItemType _itemType(String? materialType) {
    final t = (materialType ?? '').toLowerCase();
    return t.contains('non')
        ? PurchaseRequestItemType.nonInventory
        : PurchaseRequestItemType.inventory;
  }

  /// `attachments` / `delivery_notes` / `invoices` — normally a list of
  /// URL strings; `null`, an empty string or a single string are
  /// tolerated too.
  static List<PrAttachment> _attachments(dynamic raw) {
    final urls = <String>[];
    if (raw is List) {
      for (final entry in raw) {
        final url = _urlOf(entry);
        if (url != null) urls.add(url);
      }
    } else {
      final url = _urlOf(raw);
      if (url != null) urls.add(url);
    }
    return [for (final url in urls) PrAttachment.fromUrl(url)];
  }

  static String? _urlOf(dynamic entry) {
    if (entry is Map) {
      for (final key in const ['url', 'path', 'file', 'file_name']) {
        final v = _nullableStr(entry[key]);
        if (v != null) return v;
      }
      return null;
    }
    return _nullableStr(entry);
  }

  /// `pdf_path` as an absolute URL. The API sends a full URL; a
  /// host-relative or bare path is resolved against the Iungo host so it
  /// can still be opened.
  static String? _pdfUrl(dynamic raw) {
    final value = _nullableStr(raw);
    if (value == null) return null;
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }
    return value.startsWith('/')
        ? '${AppUrls.iungoHost}$value'
        : '${AppUrls.iungoHost}/$value';
  }

  static List<PrPipelineStage> _pipeline(dynamic raw) {
    if (raw is! List) return const [];
    const known = {
      'stage',
      'module',
      'state',
      'label',
      'name',
      'sno',
      'accepted_time',
    };
    final result = <PrPipelineStage>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final json = Map<String, dynamic>.from(row);
      result.add(
        PrPipelineStage(
          stage: _int(json['stage']),
          module: _str(json['module']),
          state: _str(json['state']),
          label: _str(json['label']),
          name: _str(json['name']),
          sno: _int(json['sno']),
          acceptedTime: parseApiDateTime(json['accepted_time']),
          extras: {
            for (final entry in json.entries)
              if (!known.contains(entry.key)) entry.key: entry.value,
          },
        ),
      );
    }
    return result;
  }

  static PrFilterOptions filterOptions(dynamic raw) {
    if (raw is! Map) return PrFilterOptions.empty;
    List<String> strings(dynamic v) {
      if (v is! List) return const [];
      return [
        for (final e in v)
          if (_nullableStr(e) != null) _nullableStr(e)!,
      ];
    }

    return PrFilterOptions(
      createdBy: strings(raw['created_by']),
      status: strings(raw['status']),
      contracts: strings(raw['contracts']),
    );
  }

  // ---- dates -----------------------------------------------------------

  static const Map<String, int> _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Parses a date-only API value — `12-Sep-2026` (the API's format),
  /// `2026-09-12` or `12-09-2026` — into a calendar day.
  ///
  /// The result is midday UTC on that day on purpose: `AppDateFormat`
  /// renders dates in Riyadh time (UTC+3), and midday UTC stays on the
  /// same calendar day whatever the device's timezone is (a local
  /// midnight would slip back a day for any timezone east of Riyadh).
  static DateTime? parseApiDate(dynamic raw) {
    final s = _str(raw);
    if (s.isEmpty) return null;

    int? year;
    int? month;
    int? day;

    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(s);
    final dMonY =
        RegExp(r'^(\d{1,2})[-/ ]([A-Za-z]{3,9})[-/ ,]*(\d{4})').firstMatch(s);

    if (iso != null) {
      year = int.tryParse(iso.group(1)!);
      month = int.tryParse(iso.group(2)!);
      day = int.tryParse(iso.group(3)!);
    } else if (dmy != null) {
      day = int.tryParse(dmy.group(1)!);
      month = int.tryParse(dmy.group(2)!);
      year = int.tryParse(dmy.group(3)!);
    } else if (dMonY != null) {
      day = int.tryParse(dMonY.group(1)!);
      month = _months[dMonY.group(2)!.substring(0, 3).toLowerCase()];
      year = int.tryParse(dMonY.group(3)!);
    }

    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime.utc(year, month, day, 12);
  }

  /// Parses a server timestamp such as `2026-09-12 08:47:46.050` and
  /// keeps its wall-clock components as-is (tagged UTC so nothing
  /// shifts when it is formatted).
  static DateTime? parseApiDateTime(dynamic raw) {
    final s = _str(raw);
    if (s.isEmpty) return null;
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return null;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }

  // ---- primitives ------------------------------------------------------

  static String _str(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _nullableStr(dynamic value) {
    final s = _str(value);
    return s.isEmpty ? null : s;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final t = value.trim();
      return int.tryParse(t) ?? double.tryParse(t)?.toInt();
    }
    return null;
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static bool? _flag(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final n = _int(value);
    if (n != null) return n == 1;
    final s = _str(value).toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }
}
