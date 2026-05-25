import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfExporter {
  const PdfExporter._();

  static Future<String> exportSimpleDocument({
    required String title,
    required Map<String, String> fields,
  }) async {
    final bytes = await _buildSimpleDocument(title: title, fields: fields);
    final file = await _savePdfFile(title: title, bytes: bytes);
    return file.path;
  }

  static Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'IDARA DZ PDF');
  }

  static Future<Uint8List> _buildSimpleDocument({
    required String title,
    required Map<String, String> fields,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          textDirection: pw.TextDirection.rtl,
          margin: pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'تم إنشاؤه بواسطة IDARA DZ - $now',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 28),
                  ...fields.entries.map(
                    (entry) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              entry.key,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(entry.value.isEmpty ? '-' : entry.value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<File> _savePdfFile({
    required String title,
    required Uint8List bytes,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(baseDir.path, 'idara_dz_exports'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final safeTitle = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(pdfDir.path, '${safeTitle}_$stamp.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
