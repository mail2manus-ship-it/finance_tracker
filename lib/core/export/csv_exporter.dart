import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'export_row.dart';

/// Writes [rows] to a CSV file in the app's temporary directory and
/// returns the file path, ready to be shared via `share_plus`.
class CsvExporter {
  CsvExporter._();

  static Future<File> export(List<ExportRow> rows, {required String fileNamePrefix}) async {
    final header = ['Date', 'Time', 'Type', 'Category / Source', 'Amount', 'Payment Method / Source', 'Notes'];
    final data = [
      header,
      ...rows.map((r) => [
            DateFormat('yyyy-MM-dd').format(r.dateTime),
            DateFormat('HH:mm').format(r.dateTime),
            r.type,
            r.category,
            r.amount.toStringAsFixed(2),
            r.paymentMethodOrSource,
            r.notes,
          ]),
    ];

    final csv = const ListToCsvConverter().convert(data);
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.csv');
    return file.writeAsString(csv);
  }
}
