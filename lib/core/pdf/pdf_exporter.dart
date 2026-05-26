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
    final arabicFont = await _loadAndroidArabicFont();
    final latinFont = await _loadAndroidLatinFont();
    final fallbackFonts = <pw.Font>[
      if (latinFont != null) latinFont,
    ];

    pw.TextStyle style(double size, {bool bold = false}) {
      return pw.TextStyle(
        font: arabicFont,
        fontFallback: fallbackFonts,
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        lineSpacing: 4.5,
      );
    }

    final normalStyle = style(13.3);
    final boldStyle = style(13.3, bold: true);
    final subjectStyle = style(14.2, bold: true);

    final cleanFirstName = _cleanPdfText(firstName);
    final cleanLastName = _cleanPdfText(lastName);
    final fullName = '$cleanLastName $cleanFirstName'.trim();
    final address = _cleanPdfText(
      [fullAddress, city]
          .where((part) => part.trim().isNotEmpty)
          .join(' - '),
    );

    final displayDate = _formatDateForDisplay(requestDate);
    final cleanPhone = _cleanPdfText(phone);
    final cleanNationalId = _cleanPdfText(nationalId);
    final cleanRecipient = _cleanPdfText(recipient);
    final cleanSubjectMatter = _cleanPdfText(subjectMatter);
    final cleanExperienceYears = _cleanPdfText(experienceYears);
    final cleanDegree = _cleanPdfText(degree);
    final cleanSpecialization = _cleanPdfText(specialization);
    final cleanUniversity = _cleanPdfText(university);
    final cleanGraduationYear = _cleanPdfText(graduationYear);

    pw.Widget line(String text, {pw.TextAlign align = pw.TextAlign.right, pw.TextStyle? textStyle, double bottom = 6}) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: bottom),
        child: pw.Text(
          _cleanPdfText(text),
          textDirection: pw.TextDirection.rtl,
          textAlign: align,
          style: textStyle ?? normalStyle,
        ),
      );
    }

    pw.Widget centered(String text, {pw.TextStyle? textStyle, double bottom = 10}) {
      return line(text, align: pw.TextAlign.center, textStyle: textStyle ?? boldStyle, bottom: bottom);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        pageTheme: pw.PageTheme(
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.fromLTRB(56, 68, 56, 42),
          theme: theme,
        ),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      width: 170,
                      child: pw.Text(
                        'في: $displayDate',
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                        style: normalStyle,
                      ),
                    ),
                    pw.Container(
                      width: 260,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          line('الاسم واللقب: $fullName', textStyle: boldStyle, bottom: 5),
                          line('العنوان: $address', textStyle: boldStyle, bottom: 5),
                          line('الهاتف: $cleanPhone', textStyle: boldStyle, bottom: 0),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 54),
                centered('إلى السيد: $cleanRecipient', textStyle: boldStyle, bottom: 45),
                centered(
                  'الموضوع: طلب منصب استخلاف لمنصب أستاذ في مادة $cleanSubjectMatter',
                  textStyle: subjectStyle,
                  bottom: 45,
                ),
                line(
                  'أنا الممضي أسفله الحامل لبطاقة التعريف الوطنية رقم: $cleanNationalId لي عظيم الشرف أن أتقدم إلى',
                  bottom: 8,
                ),
                line(
                  'سيادتكم المحترمة بطلبي هذا والمتمثل في طلب الحصول على منصب استخلاف بصفة أستاذ في مادة',
                  bottom: 8,
                ),
                line('$cleanSubjectMatter.', bottom: 24),
                line(
                  'كما أحيطكم علماً أنني متحصل على شهادة $cleanDegree تخصص $cleanSpecialization، خريج سنة $cleanGraduationYear',
                  bottom: 8,
                ),
                line('من $cleanUniversity.', bottom: 24),
                line(
                  'ولدي خبرة في مجال التدريس تقدر بـ ($cleanExperienceYears) سنوات، ولدي الرغبة والقدرة الكاملة على أداء هذه المهمة',
                  bottom: 8,
                ),
                line('التربوية.', bottom: 54),
                centered('في انتظار ردكم الإيجابي، تقبلوا مني فائق الاحترام والتقدير.', textStyle: normalStyle, bottom: 88),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'توقيع المعني:',
                    textDirection: pw.TextDirection.rtl,
                    style: normalStyle,
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

  static String _cleanPdfText(String value) {
    return value
        .replaceAll(RegExp(r'[\uFFFD\u25A1\u25A0\u200e\u200f\u202a-\u202e]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _formatDateForDisplay(String value) {
    final cleaned = _cleanPdfText(value);
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'[\-/\\.]')).where((p) => p.trim().isNotEmpty).toList();
    if (parts.length == 3 && parts.first.length == 4) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return cleaned;
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

  static Future<pw.Font?> _loadAndroidLatinFont() async {
    final candidates = <String>[
      '/system/fonts/Roboto-Regular.ttf',
      '/system/fonts/NotoSans-Regular.ttf',
      '/system/fonts/DroidSans.ttf',
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
