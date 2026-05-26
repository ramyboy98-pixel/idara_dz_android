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
    final fullName = '$lastName $firstName'.trim();
    final address = [fullAddress, city]
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');

    const normalStyle = pw.TextStyle(fontSize: 13.5, lineSpacing: 5);
    final boldStyle = pw.TextStyle(fontSize: 13.5, fontWeight: pw.FontWeight.bold, lineSpacing: 5);
    final subjectStyle = pw.TextStyle(fontSize: 14.5, fontWeight: pw.FontWeight.bold, lineSpacing: 5);

    pw.Widget paragraph(List<pw.InlineSpan> spans) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.RichText(
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.right,
          text: pw.TextSpan(style: normalStyle, children: spans),
        ),
      );
    }

    pw.TextSpan normal(String text) => pw.TextSpan(text: text);
    pw.TextSpan strong(String text) => pw.TextSpan(text: text, style: boldStyle);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        pageTheme: pw.PageTheme(
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.fromLTRB(42, 46, 42, 42),
          theme: theme,
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _fixedInfoLine(label: 'في:', value: requestDate, style: normalStyle, boldStyle: boldStyle),
                _fixedInfoLine(label: 'الاسم واللقب:', value: fullName, style: normalStyle, boldStyle: boldStyle),
                _fixedInfoLine(label: 'العنوان:', value: address, style: normalStyle, boldStyle: boldStyle),
                _fixedInfoLine(label: 'الهاتف:', value: phone, style: normalStyle, boldStyle: boldStyle),
                pw.SizedBox(height: 13),
                _fixedInfoLine(label: 'إلى السيد:', value: recipient, style: normalStyle, boldStyle: boldStyle),
                pw.SizedBox(height: 13),
                pw.RichText(
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                  text: pw.TextSpan(
                    style: subjectStyle,
                    children: [
                      const pw.TextSpan(text: 'الموضوع: طلب منصب استخلاف لمنصب أستاذ في مادة '),
                      pw.TextSpan(text: subjectMatter, style: subjectStyle),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),
                paragraph([
                  normal('أنا الممضي أسفله الحامل لبطاقة التعريف الوطنية رقم: '),
                  strong(nationalId),
                  normal(' لي عظيم الشرف أن أتقدم إلى سيادتكم المحترمة بطلبي هذا والمتمثل في طلب الحصول على منصب استخلاف بصفة أستاذ في مادة '),
                  strong(subjectMatter),
                  normal('.'),
                ]),
                paragraph([
                  normal('كما أحيطكم علماً أنني متحصل على شهادة '),
                  strong(degree),
                  normal(' تخصص '),
                  strong(specialization),
                  normal('، خريج سنة '),
                  strong(graduationYear),
                  normal(' من '),
                  strong(university),
                  normal('.'),
                ]),
                paragraph([
                  normal('ولدي خبرة في مجال التدريس تقدر بـ ('),
                  strong(experienceYears),
                  normal(') سنوات، ولدي الرغبة والقدرة الكاملة على أداء هذه المهمة التربوية.'),
                ]),
                paragraph([
                  normal('في انتظار ردكم الإيجابي، تقبلوا مني فائق الاحترام والتقدير.'),
                ]),
                pw.SizedBox(height: 34),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'توقيع المعني:',
                    textDirection: pw.TextDirection.rtl,
                    style: boldStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _fixedInfoLine({
    required String label,
    required String value,
    required pw.TextStyle style,
    required pw.TextStyle boldStyle,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.RichText(
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.right,
        text: pw.TextSpan(
          style: style,
          children: [
            pw.TextSpan(text: '$label ', style: boldStyle),
            pw.TextSpan(text: value.trim().isEmpty ? '........................' : value.trim()),
          ],
        ),
      ),
    );
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
