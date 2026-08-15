import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export_row.dart';

/// Builds a formatted PDF report (title, date range, summary totals, then
/// a transaction table) and returns the file path.
class PdfExporter {
  PdfExporter._();

  static Future<File> export(
    List<ExportRow> rows, {
    required String fileNamePrefix,
    required String periodLabel,
    required double totalIncome,
    required double totalExpense,
    String currencySymbol = '₹',
  }) async {
    final doc = pw.Document();
    final currency = NumberFormat('#,##0.00');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'My Personal Finance Tracker',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(periodLabel, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('Income', '$currencySymbol${currency.format(totalIncome)}', PdfColors.green700),
              _summaryBox('Expense', '$currencySymbol${currency.format(totalExpense)}', PdfColors.red700),
              _summaryBox(
                'Savings',
                '$currencySymbol${currency.format(totalIncome - totalExpense)}',
                PdfColors.blue700,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Time', 'Type', 'Category / Source', 'Amount', 'Method / Source', 'Notes'],
            data: rows
                .map((r) => [
                      DateFormat('dd MMM yyyy').format(r.dateTime),
                      DateFormat('hh:mm a').format(r.dateTime),
                      r.type,
                      r.category,
                      currency.format(r.amount),
                      r.paymentMethodOrSource,
                      r.notes,
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo400),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.pdf');
    return file.writeAsBytes(await doc.save());
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }
}
