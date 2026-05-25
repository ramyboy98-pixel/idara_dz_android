import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfExporter {
  const PdfExporter._();

  static Future<String> exportTemplateDocument({
    required String title,
    required String? templateFilePath,
    required Map<String, String> valuesByKey,
    required Map<String, String> valuesByLabel,
  }) async {
    final templatePath = templateFilePath?.trim() ?? '';

    if (templatePath.isNotEmpty && await File(templatePath).exists()) {
      final extension = p.extension(templatePath).toLowerCase();
      if (extension == '.txt' || extension == '.md') {
        final templateText = await File(templatePath).readAsString();
        final filledText = fillPlaceholders(
          templateText: templateText,
          valuesByKey: valuesByKey,
          valuesByLabel: valuesByLabel,
        );
        final bytes = await _buildTextTemplateDocument(
          title: title,
          filledText: filledText,
          valuesByLabel: valuesByLabel,
        );
        final file = await _savePdfFile(title: title, bytes: bytes);
        return file.path;
      }
    }

    final bytes = await _buildSimpleDocument(title: title, fields: valuesByLabel);
    final file = await _savePdfFile(title: title, bytes: bytes);
    return file.path;
  }

  static Future<String> exportSimpleDocument({
    required String title,
    required Map<String, String> fields,
  }) async {
    final bytes = await _buildSimpleDocument(title: title, fields: fields);
    final file = await _savePdfFile(title: title, bytes: bytes);
    return file.path;
  }

  static String fillPlaceholders({
    required String templateText,
    required Map<String, String> valuesByKey,
    required Map<String, String> valuesByLabel,
  }) {
    var output = templateText;

    for (final entry in valuesByKey.entries) {
      output = output.replaceAll('{{${entry.key}}}', entry.value);
    }

    for (final entry in valuesByLabel.entries) {
      final normalizedLabel = normalizePlaceholderKey(entry.key);
      output = output.replaceAll('{{${entry.key}}}', entry.value);
      output = output.replaceAll('{{$normalizedLabel}}', entry.value);
    }

    return output;
  }

  static String normalizePlaceholderKey(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[{}]'), '')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'IDARA DZ PDF');
  }

  static Future<String?> savePdfToPhone({
    required String sourcePath,
    required String title,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('ملف PDF غير موجود.');
    }

    final bytes = await sourceFile.readAsBytes();
    final safeTitle = _safeFileName(title);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    return FilePicker.platform.saveFile(
      dialogTitle: 'حفظ ملف PDF',
      fileName: '${safeTitle}_$stamp.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
  }

  static Future<Uint8List> _buildTextTemplateDocument({
    required String title,
    required String filledText,
    required Map<String, String> valuesByLabel,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.now());
    final lines = filledText.split(RegExp(r'\r?\n'));

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
                  ...lines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Text(
                        line.isEmpty ? ' ' : line,
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 14, lineSpacing: 6),
                      ),
                    ),
                  ),
                  if (_hasUnfilledPlaceholders(filledText)) ...[
                    pw.SizedBox(height: 18),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.orange300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'تنبيه: بقيت رموز غير معوضة داخل النموذج. تأكد أن أسماء الحقول مطابقة للرموز.',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.orange900),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
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

  static bool _hasUnfilledPlaceholders(String text) {
    return RegExp(r'\{\{[^}]+\}\}').hasMatch(text);
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

    final safeTitle = _safeFileName(title);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(pdfDir.path, '${safeTitle}_$stamp.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _safeFileName(String title) {
    final normalized = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'IDARA_DZ' : normalized;
  }
}
