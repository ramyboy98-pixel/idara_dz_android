import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
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

    }

    final bytes = await _buildSimpleDocument(title: title, fields: valuesByLabel);
    final file = await _savePdfFile(title: title, bytes: bytes);
    return file.path;
  }


  static Future<String> exportImageTemplateDocument({
    required String title,
    String? templateFilePath,
    Map<String, String>? valuesByKey,
    Map<String, String>? valuesByLabel,
    List<dynamic>? fields,
    List<dynamic>? positions,
    Map<int, String>? valuesByFieldId,
  }) async {
    final labels = Map<String, String>.from(valuesByLabel ?? <String, String>{});
    final keys = Map<String, String>.from(valuesByKey ?? <String, String>{});

    if (fields != null && valuesByFieldId != null) {
      for (final field in fields) {
        try {
          final int? fieldId = (field.id as int?) ?? (field.sortOrder as int?);
          if (fieldId == null) {
            continue;
          }
          final String value = valuesByFieldId[fieldId] ?? '';
          labels[field.label as String] = value;
          keys[field.keyName as String] = value;
        } catch (_) {
          // Keep this method compatible with older template experiments.
        }
      }
    }

    return exportTemplateDocument(
      title: title,
      templateFilePath: templateFilePath,
      valuesByKey: keys,
      valuesByLabel: labels,
    );
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


  static Future<String> exportSubstitutionRequest({
    required String requestDate,
    required String firstName,
    required String lastName,
    required String fullAddress,
    required String city,
    required String phone,
    required String nationalId,
    required String recipient,
    required String subjectMatter,
    required String experienceYears,
    required String degree,
    required String specialization,
    required String university,
    required String graduationYear,
  }) async {
    final bytes = await _buildSubstitutionRequestDocument(
      requestDate: requestDate,
      firstName: firstName,
      lastName: lastName,
      fullAddress: fullAddress,
      city: city,
      phone: phone,
      nationalId: nationalId,
      recipient: recipient,
      subjectMatter: subjectMatter,
      experienceYears: experienceYears,
      degree: degree,
      specialization: specialization,
      university: university,
      graduationYear: graduationYear,
    );
    final file = await _savePdfFile(title: 'طلب منصب استخلاف', bytes: bytes);
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


  static Future<Uint8List> _buildSubstitutionRequestDocument({
    required String requestDate,
    required String firstName,
    required String lastName,
    required String fullAddress,
    required String city,
    required String phone,
    required String nationalId,
    required String recipient,
    required String subjectMatter,
    required String experienceYears,
    required String degree,
    required String specialization,
    required String university,
    required String graduationYear,
  }) async {
    final pdf = pw.Document();
    final theme = await _buildArabicPdfTheme();
    final fullName = _cleanPdfText('$lastName $firstName'.trim());
    final address = _cleanPdfText(
      [fullAddress, city]
          .where((part) => part.trim().isNotEmpty)
          .join(' - '),
    );

    final backgroundBytes =
        await rootBundle.load('assets/templates/substitution_request_blank.png');
    final background = pw.MemoryImage(backgroundBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: theme,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(background, fit: pw.BoxFit.fill),
              ),

              // أعلى الصفحة
              _templateValue(left: 104, top: 78, width: 90, text: _cleanPdfText(requestDate)),
              _templateValue(left: 382, top: 111, width: 160, text: fullName),
              _templateValue(left: 395, top: 139, width: 150, text: address),
              _templateValue(left: 405, top: 167, width: 130, text: _cleanPdfText(phone)),

              // وسط الصفحة
              _templateValue(left: 210, top: 236, width: 250, text: _cleanPdfText(recipient), fontSize: 13.5, bold: true),
              _templateValue(left: 177, top: 296, width: 190, text: _cleanPdfText(subjectMatter), fontSize: 13.5, bold: true),

              // الفقرة الأولى
              _templateValue(left: 173, top: 355, width: 160, text: _cleanPdfText(nationalId)),
              _templateValue(left: 104, top: 428, width: 175, text: _cleanPdfText(subjectMatter)),

              // فقرة الشهادة
              _templateValue(left: 390, top: 489, width: 120, text: _cleanPdfText(degree)),
              _templateValue(left: 230, top: 489, width: 110, text: _cleanPdfText(specialization)),
              _templateValue(left: 98, top: 489, width: 52, text: _cleanPdfText(graduationYear)),
              _templateValue(left: 295, top: 525, width: 240, text: _cleanPdfText(university)),

              // الخبرة
              _templateValue(left: 330, top: 587, width: 35, text: _cleanPdfText(experienceYears), align: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _templateValue({
    required double left,
    required double top,
    required double width,
    required String text,
    double fontSize = 12.8,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.right,
  }) {
    return pw.Positioned(
      left: left,
      top: top,
      child: pw.SizedBox(
        width: width,
        child: pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
          text.trim(),
          maxLines: 2,
          softWrap: true,
          overflow: pw.TextOverflow.clip,
          textAlign: align,
          textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              lineSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  static String _cleanPdfText(String text) {
    return text
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e]'), '')
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), '')
        .replaceAll('�', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
