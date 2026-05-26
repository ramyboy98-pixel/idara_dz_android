import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/template_field.dart';
import '../../data/models/template_field_position.dart';

class PdfExporter {
  const PdfExporter._();

  static Future<String> exportImageTemplateDocument({
    required String title,
    required String? templateFilePath,
    required List<TemplateField> fields,
    required List<TemplateFieldPosition> positions,
    required Map<int, String> valuesByFieldId,
  }) async {
    final templatePath = templateFilePath?.trim() ?? '';
    final file = File(templatePath);
    if (templatePath.isEmpty || !await file.exists()) {
      final fallback = <String, String>{
        for (final field in fields) field.label: valuesByFieldId[field.id ?? -1] ?? '',
      };
      final bytes = await _buildSimpleDocument(title: title, fields: fallback);
      final savedFile = await _savePdfFile(title: title, bytes: bytes);
      return savedFile.path;
    }

    final extension = p.extension(templatePath).toLowerCase();
    if (!['.png', '.jpg', '.jpeg', '.webp'].contains(extension)) {
      final fallback = <String, String>{
        for (final field in fields) field.label: valuesByFieldId[field.id ?? -1] ?? '',
      };
      final bytes = await _buildSimpleDocument(title: title, fields: fallback);
      final savedFile = await _savePdfFile(title: title, bytes: bytes);
      return savedFile.path;
    }

    final imageBytes = await file.readAsBytes();
    final bytes = await _buildImageOverlayDocument(
      imageBytes: imageBytes,
      fields: fields,
      positions: positions,
      valuesByFieldId: valuesByFieldId,
    );
    final savedFile = await _savePdfFile(title: title, bytes: bytes);
    return savedFile.path;
  }

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

  static Future<Uint8List> _buildImageOverlayDocument({
    required Uint8List imageBytes,
    required List<TemplateField> fields,
    required List<TemplateFieldPosition> positions,
    required Map<int, String> valuesByFieldId,
  }) async {
    final pdf = pw.Document();
    final theme = await _buildArabicPdfTheme();
    final background = pw.MemoryImage(imageBytes);
    final positionsByFieldId = <int, TemplateFieldPosition>{
      for (final position in positions) position.fieldId: position,
    };

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          final pageWidth = PdfPageFormat.a4.width;
          final pageHeight = PdfPageFormat.a4.height;

          return pw.Stack(
            children: [
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Image(
                  background,
                  width: pageWidth,
                  height: pageHeight,
                  fit: pw.BoxFit.fill,
                ),
              ),
              ...fields.map((field) {
                final fieldId = field.id;
                if (fieldId == null) return pw.SizedBox.shrink();
                final position = positionsByFieldId[fieldId];
                if (position == null) return pw.SizedBox.shrink();
                final value = valuesByFieldId[fieldId]?.trim() ?? '';
                if (value.isEmpty) return pw.SizedBox.shrink();

                return pw.Positioned(
                  left: position.x * pageWidth,
                  top: position.y * pageHeight,
                  child: pw.Container(
                    width: pageWidth * 0.38,
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.rtl,
                      child: pw.Text(
                        value,
                        textAlign: pw.TextAlign.right,
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          fontSize: position.fontSize,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
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
    final theme = await _buildArabicPdfTheme();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
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
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 18),
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
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              entry.value.isEmpty ? '-' : entry.value,
                              textDirection: pw.TextDirection.rtl,
                            ),
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

  static Future<pw.ThemeData> _buildArabicPdfTheme() async {
    final regular = await _loadAndroidArabicFont();
    if (regular == null) {
      return pw.ThemeData.base();
    }
    return pw.ThemeData.withFont(base: regular, bold: regular);
  }

  static Future<pw.Font?> _loadAndroidArabicFont() async {
    final candidates = <String>[
      '/system/fonts/NotoNaskhArabic-Regular.ttf',
      '/system/fonts/NotoSansArabic-Regular.ttf',
      '/system/fonts/DroidNaskh-Regular.ttf',
      '/system/fonts/Roboto-Regular.ttf',
    ];

    for (final path in candidates) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.Font.ttf(bytes.buffer.asByteData());
      }
    }

    return null;
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
