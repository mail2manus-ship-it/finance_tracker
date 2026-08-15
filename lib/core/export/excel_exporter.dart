import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'export_row.dart';

/// Writes [rows] to a single-sheet .xlsx workbook (plus a small summary
/// section at the top) and returns the file path.
class ExcelExporter {
  ExcelExporter._();

  static Future<File> export(
    List<ExportRow> rows, {
    required String fileNamePrefix,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final workbook = Excel.createExcel();
    final sheet = workbook['Transactions'];
    // Excel.createExcel() ships a default 'Sheet1' -- drop it so only
    // our named sheet remains.
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.delete('Sheet1');
    }

    sheet.appendRow([TextCellValue('My Personal Finance Tracker — Export')]);
    sheet.appendRow([TextCellValue('Total Income'), DoubleCellValue(totalIncome)]);
    sheet.appendRow([TextCellValue('Total Expense'), DoubleCellValue(totalExpense)]);
    sheet.appendRow([TextCellValue('Net Savings'), DoubleCellValue(totalIncome - totalExpense)]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Type'),
      TextCellValue('Category / Source'),
      TextCellValue('Amount'),
      TextCellValue('Payment Method / Source'),
      TextCellValue('Notes'),
    ]);

    for (final r in rows) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(r.dateTime)),
        TextCellValue(DateFormat('HH:mm').format(r.dateTime)),
        TextCellValue(r.type),
        TextCellValue(r.category),
        DoubleCellValue(r.amount),
        TextCellValue(r.paymentMethodOrSource),
        TextCellValue(r.notes),
      ]);
    }

    final bytes = workbook.encode();
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.xlsx');
    return file.writeAsBytes(bytes!);
  }
}
