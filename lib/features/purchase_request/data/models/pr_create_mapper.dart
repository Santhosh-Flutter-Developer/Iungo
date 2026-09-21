import 'package:iungo/features/purchase_request/data/datasources/pr_create_exceptions.dart';
import 'package:iungo/features/purchase_request/domain/entities/contract_option.dart';
import 'package:iungo/features/purchase_request/domain/entities/material_option.dart';

/// One page of Inventory materials plus the raw item count the server
/// returned — a full page suggests another one exists (same convention
/// as `InventoryRequestListPageResult`).
class MaterialPageResult {
  const MaterialPageResult({required this.items, required this.rawCount});

  final List<MaterialOption> items;
  final int rawCount;
}

/// Parses the responses used by the Create Purchase Request flow. Every
/// field is read defensively (PHP/Facilio can return numbers as strings
/// and empty objects as `[]`), so a malformed row is skipped rather than
/// crashing the whole list.
class PrCreateMapper {
  PrCreateMapper._();

  /// `fetch_contract_code` →
  /// `{"code":200,"data":[{"contract_id","contract_name","contract_code","margin"}]}`.
  static List<ContractOption> contracts(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List) return const [];

    final result = <ContractOption>[];
    for (final row in data) {
      if (row is! Map) continue;
      final id = _str(row['contract_id']);
      final name = _str(row['contract_name']);
      final code = _str(row['contract_code']);
      if (id.isEmpty || (code.isEmpty && name.isEmpty)) continue;
      result.add(
        ContractOption(
          contractId: id,
          contractName: name,
          // The dropdown shows the code; fall back to the name if a
          // contract somehow has none so it never renders blank.
          contractCode: code.isNotEmpty ? code : name,
          margin: _double(row['margin']) ?? 0,
        ),
      );
    }
    return result;
  }

  /// Facilio `inventoryrequest` list → only `id`, `name`, `description`.
  static MaterialPageResult materials(Map<String, dynamic> body) {
    final data = body['data'];
    final raw = (data is Map) ? data['inventoryrequest'] : null;
    final rows = (raw is List) ? raw : const [];

    final items = <MaterialOption>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final id = _int(row['id']);
      final name = _str(row['name']);
      if (id == null || name.isEmpty) continue;
      items.add(
        MaterialOption(
          id: id,
          name: name,
          description: _str(row['description']),
        ),
      );
    }
    return MaterialPageResult(items: items, rawCount: rows.length);
  }

  /// `file_uploads.php` → the stored filename the PR save API expects in
  /// `attachments` (`data.saved_name`, falling back to `data.file_name`).
  static String uploadedFileName(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map) {
      final saved = _str(data['saved_name']);
      if (saved.isNotEmpty) return saved;
      final original = _str(data['file_name']);
      if (original.isNotEmpty) return original;
    }
    throw const PrCreateException(PrCreateFailure.invalidResponse);
  }

  static String _str(dynamic value) => value?.toString().trim() ?? '';

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
