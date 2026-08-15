import 'package:share_plus/share_plus.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/income_model.dart';
import 'csv_exporter.dart';
import 'excel_exporter.dart';
import 'export_row.dart';
import 'pdf_exporter.dart';

enum ExportFormat { pdf, excel, csv }

/// Single entry point Reports screen calls into. Converts Expense/Income
/// models to the format-agnostic [ExportRow], delegates to the right
/// exporter, then opens the OS share sheet so the user can save it to
/// Drive, email it, etc. -- there's no cloud upload here, per the spec's
/// "local backup" / offline-first requirement.
class ReportExportService {
  ReportExportService._();

  static Future<void> exportAndShare({
    required ExportFormat format,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> incomes,
    required String periodLabel,
  }) async {
    final rows = <ExportRow>[
      ...expenses.map((e) => ExportRow(
            dateTime: e.dateTime,
            type: 'Expense',
            category: e.displayCategory,
            amount: e.amount,
            paymentMethodOrSource: e.paymentMethod,
            notes: e.notes ?? '',
          )),
      ...incomes.map((i) => ExportRow(
            dateTime: i.dateTime,
            type: 'Income',
            category: i.source,
            amount: i.amount,
            paymentMethodOrSource: i.source,
            notes: i.notes ?? '',
          )),
    ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final totalIncome = incomes.fold(0.0, (s, i) => s + i.amount);
    final totalExpense = expenses.fold(0.0, (s, e) => s + e.amount);

    final file = switch (format) {
      ExportFormat.csv => await CsvExporter.export(rows, fileNamePrefix: 'finance_report'),
      ExportFormat.excel => await ExcelExporter.export(
          rows,
          fileNamePrefix: 'finance_report',
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ),
      ExportFormat.pdf => await PdfExporter.export(
          rows,
          fileNamePrefix: 'finance_report',
          periodLabel: periodLabel,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
        ),
    };

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My Personal Finance Tracker — $periodLabel report',
      ),
    );
  }
}
