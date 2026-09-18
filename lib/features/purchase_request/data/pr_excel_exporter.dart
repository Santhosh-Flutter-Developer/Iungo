import 'dart:io';

import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:iungo/core/utils/app_date_format.dart';
import 'package:iungo/features/purchase_request/domain/entities/approval_pipeline.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:iungo/features/purchase_request/domain/entities/purchase_request_status.dart';

/// Builds and opens an `.xlsx` export of the PR Dashboard list — mirrors
/// the reference web app's "export" icon above the Purchase Request
/// table (Number/Date/Contract/Total/Status/Next Approval/Stage
/// columns). Kept as a standalone data-layer helper (rather than living
/// on the controller) so the sheet-building logic can be unit tested
/// and reused by GRN/Invoice dashboards later.
class PrExcelExporter {
  PrExcelExporter._();

  /// Builds one sheet named [sheetName] from [requests], saves it to the
  /// app's temp directory as [fileName], and hands it off to the OS's
  /// default viewer via `open_filex` (same pattern already used for
  /// downloaded attachments elsewhere in the app). Returns the saved
  /// file path.
  static Future<String> exportAndOpen({
    required List<PurchaseRequest> requests,
    required String sheetName,
    required String fileName,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    excel.rename(defaultSheet!, sheetName);
    final sheet = excel[sheetName];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#652E68'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    const headers = [
      'Number',
      'Date',
      'Contract',
      'Total (SAR)',
      'Status',
      'Next Approval',
      'Stage',
    ];
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < requests.length; row++) {
      final request = requests[row];
      final rowIndex = row + 1;
      final pipeline = ApprovalPipeline.forRequest(request);
      final values = <CellValue>[
        TextCellValue(request.prNumber),
        TextCellValue(AppDateFormat.mediumDate(request.requestDate)),
        TextCellValue(request.contract),
        DoubleCellValue(request.totalAmount),
        TextCellValue(request.status.excelLabel),
        TextCellValue(request.nextApprovalName ?? '--'),
        TextCellValue('${pipeline.currentStage}/${pipeline.totalStages}'),
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex,
            ))
            .value = values[col];
      }
    }

    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 18);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode the Excel workbook');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(path);
    return path;
  }
}

extension on PurchaseRequestStatus {
  String get excelLabel {
    switch (this) {
      case PurchaseRequestStatus.pending:
        return 'Pending';
      case PurchaseRequestStatus.approved:
        return 'Approved';
      case PurchaseRequestStatus.rejected:
        return 'Rejected';
    }
  }
}
