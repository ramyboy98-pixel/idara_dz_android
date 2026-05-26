import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
          filledText: filledText,
        );
        final file = await _savePdfFile(title: title, bytes: bytes);
        return file.path;
      }

      if (extension == '.docx') {
        final templateText = await _extractTextFromDocx(templatePath);
        final filledText = fillPlaceholders(
          templateText: templateText,
          valuesByKey: valuesByKey,
          valuesByLabel: valuesByLabel,
        );
        final bytes = await _buildTextTemplateDocument(
          filledText: filledText,
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
    final replacements = <String, String>{};

    void addReplacement(String rawKey, String value) {
      final key = rawKey.trim();
      if (key.isEmpty) return;

      replacements[key] = value;
      replacements[normalizePlaceholderKey(key)] = value;
      replacements[_compactPlaceholderKey(key)] = value;
    }

    for (final entry in valuesByKey.entries) {
      addReplacement(entry.key, entry.value);
    }

    for (final entry in valuesByLabel.entries) {
      addReplacement(entry.key, entry.value);
    }

    return templateText.replaceAllMapped(
      RegExp(r'\{\{([\s\S]*?)\}\}'),
      (match) {
        final rawPlaceholder = match.group(1) ?? '';
        final candidates = <String>[
          rawPlaceholder.trim(),
          normalizePlaceholderKey(rawPlaceholder),
          _compactPlaceholderKey(rawPlaceholder),
        ];

        for (final candidate in candidates) {
          final value = replacements[candidate];
          if (value != null) return value;
        }

        // Unknown placeholders should not appear as broken squares in the final PDF.
        return '';
      },
    );
  }

  static String normalizePlaceholderKey(String text) {
    return text
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e]'), '')
        .replaceAll(RegExp(r'[\u064b-\u065f\u0670]'), '')
        .replaceAll('ـ', '')
        .trim()
        .replaceAll(RegExp(r'[{}]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _compactPlaceholderKey(String text) {
    return normalizePlaceholderKey(text).replaceAll('_', '').toLowerCase();
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
    required String filledText,
  }) async {
    final pdf = pw.Document();
    final lines = filledText.split(RegExp(r'\r?\n'));
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
                  ...lines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Text(
                        line.trim().isEmpty ? ' ' : line,
                        textAlign: pw.TextAlign.right,
                        textDirection: pw.TextDirection.rtl,
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
                        textDirection: pw.TextDirection.rtl,
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

  static Future<String> _extractTextFromDocx(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = archive.files.firstWhere(
      (file) => file.name == 'word/document.xml',
      orElse: () => throw Exception('ملف DOCX غير صالح: لم يتم العثور على word/document.xml'),
    );

    final xml = utf8.decode(documentFile.content as List<int>, allowMalformed: true);
    final bodyMatch = RegExp(r'<w:body[\s\S]*?</w:body>').firstMatch(xml);
    final bodyXml = bodyMatch?.group(0) ?? xml;

    final blocks = <String>[];
    final blockMatches = RegExp(
      r'<w:(p|tbl)\b[\s\S]*?</w:\1>',
      multiLine: true,
    ).allMatches(bodyXml);

    for (final blockMatch in blockMatches) {
      final blockXml = blockMatch.group(0) ?? '';
      if (blockXml.startsWith('<w:tbl')) {
        final tableText = _extractDocxTableText(blockXml);
        if (tableText.trim().isNotEmpty) {
          blocks.add(tableText);
        }
      } else {
        final paragraphText = _extractDocxParagraphText(blockXml);
        if (paragraphText.trim().isNotEmpty) {
          blocks.add(paragraphText);
        } else if (blocks.isNotEmpty && blocks.last.isNotEmpty) {
          blocks.add('');
        }
      }
    }

    final text = _cleanExtractedDocxText(blocks.join('\n'));
    if (text.trim().isEmpty) {
      throw Exception('لم يتم استخراج نص من ملف DOCX.');
    }
    return text;
  }

  static String _extractDocxTableText(String tableXml) {
    final rows = <String>[];
    final rowMatches = RegExp(
      r'<w:tr\b[\s\S]*?</w:tr>',
      multiLine: true,
    ).allMatches(tableXml);

    for (final rowMatch in rowMatches) {
      final rowXml = rowMatch.group(0) ?? '';
      final cells = <String>[];
      final cellMatches = RegExp(
        r'<w:tc\b[\s\S]*?</w:tc>',
        multiLine: true,
      ).allMatches(rowXml);

      for (final cellMatch in cellMatches) {
        final cellXml = cellMatch.group(0) ?? '';
        final paragraphs = RegExp(
          r'<w:p\b[\s\S]*?</w:p>',
          multiLine: true,
        ).allMatches(cellXml).map((match) {
          return _extractDocxParagraphText(match.group(0) ?? '');
        }).where((value) => value.trim().isNotEmpty).toList();

        final cellText = paragraphs.join(' ').trim();
        if (cellText.isNotEmpty) {
          cells.add(cellText);
        }
      }

      if (cells.isNotEmpty) {
        rows.add(cells.join('     '));
      }
    }

    return rows.join('\n');
  }

  static String _extractDocxParagraphText(String paragraphXml) {
    final preparedXml = paragraphXml
        .replaceAll(RegExp(r'<w:tab\s*/>'), '     ')
        .replaceAll(RegExp(r'<w:br\s*/>'), '\n')
        .replaceAll(RegExp(r'<w:cr\s*/>'), '\n');

    final textMatches = RegExp(
      r'<w:t(?:\s[^>]*)?>([\s\S]*?)</w:t>',
      multiLine: true,
    ).allMatches(preparedXml);

    final buffer = StringBuffer();
    for (final textMatch in textMatches) {
      buffer.write(_decodeXmlText(textMatch.group(1) ?? ''));
    }
    return buffer.toString().trimRight();
  }

  static String _cleanExtractedDocxText(String value) {
    return value
        .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '')
        .replaceAll(RegExp(r'[\uE000-\uF8FF\uFFFC]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]{2,}'), '     ').trimRight())
        .join('\n')
        .trim();
  }

  static String _decodeXmlText(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
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
