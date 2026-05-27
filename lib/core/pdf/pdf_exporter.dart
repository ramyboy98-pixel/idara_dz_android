import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfExporter {
  const PdfExporter._();

  static const MethodChannel _pdfChannel = MethodChannel('idara_dz/pdf');

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
    final html = _buildSubstitutionRequestHtml(
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

    final file = await _createOutputFile(title: 'طلب منصب استخلاف');
    await _htmlToPdf(html: html, outputPath: file.path);
    return file.path;
  }

  static Future<String> exportSimpleDocument({
    required String title,
    required Map<String, String> fields,
  }) async {
    final rows = fields.entries
        .map(
          (entry) => '''
          <tr>
            <th>${_escapeHtml(entry.key)}</th>
            <td>${_escapeHtml(entry.value)}</td>
          </tr>
          ''',
        )
        .join();

    final html = _wrapA4Html('''
      <div class="simple-title">${_escapeHtml(title)}</div>
      <table class="simple-table">$rows</table>
    ''');

    final file = await _createOutputFile(title: title);
    await _htmlToPdf(html: html, outputPath: file.path);
    return file.path;
  }

  static Future<String> exportTemplateDocument({
    required String title,
    required String? templateFilePath,
    required Map<String, String> valuesByKey,
    required Map<String, String> valuesByLabel,
  }) async {
    final templatePath = templateFilePath?.trim() ?? '';
    String content = '';

    if (templatePath.isNotEmpty && await File(templatePath).exists()) {
      final extension = p.extension(templatePath).toLowerCase();
      if (extension == '.txt' || extension == '.md') {
        content = await File(templatePath).readAsString();
        content = fillPlaceholders(
          templateText: content,
          valuesByKey: valuesByKey,
          valuesByLabel: valuesByLabel,
        );
      }
    }

    if (content.trim().isEmpty) {
      return exportSimpleDocument(title: title, fields: valuesByLabel);
    }

    final html = _wrapA4Html('''
      <div class="simple-title">${_escapeHtml(title)}</div>
      <div class="text-template">${_textToHtml(content)}</div>
    ''');

    final file = await _createOutputFile(title: title);
    await _htmlToPdf(html: html, outputPath: file.path);
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
          final int? fieldId = field.id is int ? field.id as int : field.sortOrder as int?;
          if (fieldId == null) continue;
          final value = valuesByFieldId[fieldId] ?? '';
          labels[field.label as String] = value;
          keys[field.keyName as String] = value;
        } catch (_) {
          // Backward compatibility with removed experimental screens.
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

    return templateText.replaceAllMapped(RegExp(r'\{\{([\s\S]*?)\}\}'), (match) {
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
      return '';
    });
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
        .replaceAll(RegExp(r'^_|_\$'), '');
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

  static Future<File> _createOutputFile({required String title}) async {
    final directory = await getApplicationDocumentsDirectory();
    final outputDirectory = Directory(p.join(directory.path, 'generated_pdfs'));
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final safeTitle = _safeFileName(title);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return File(p.join(outputDirectory.path, '${safeTitle}_$stamp.pdf'));
  }

  static Future<void> _htmlToPdf({
    required String html,
    required String outputPath,
  }) async {
    await _pdfChannel.invokeMethod<void>('htmlToPdf', <String, dynamic>{
      'html': html,
      'outputPath': outputPath,
    });
  }

  static String _buildSubstitutionRequestHtml({
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
  }) {
    final fullName = _cleanText('$lastName $firstName');
    final address = _joinClean([fullAddress, city], separator: ' - ');
    final matter = _cleanText(subjectMatter);
    final years = _cleanText(experienceYears);

    return _wrapA4Html('''
      <section class="substitution-page">
        <header class="top-block">
          <div class="date-block">في: <span>${_escapeHtml(_cleanText(requestDate))}</span></div>
          <div class="person-block">
            <div>الاسم واللقب: <span>${_escapeHtml(fullName)}</span></div>
            <div>العنوان: <span>${_escapeHtml(address)}</span></div>
            <div>الهاتف: <span dir="ltr">${_escapeHtml(_cleanText(phone))}</span></div>
          </div>
        </header>

        <main class="substitution-content">
          <p class="recipient">إلى السيد: <strong>${_escapeHtml(_cleanText(recipient))}</strong></p>

          <p class="subject">الموضوع: <strong>طلب منصب استخلاف لمنصب أستاذ في مادة ${_escapeHtml(matter)}</strong></p>

          <p>
            أنا الممضي أسفله الحامل لبطاقة التعريف الوطنية رقم:
            <span dir="ltr">${_escapeHtml(_cleanText(nationalId))}</span>
            لي عظيم الشرف أن أتقدم إلى سيادتكم المحترمة بطلبي هذا والمتمثل في طلب الحصول على منصب استخلاف بصفة أستاذ في مادة ${_escapeHtml(matter)}.
          </p>

          <p>
            كما أحيطكم علماً أنني متحصل على شهادة ${_escapeHtml(_cleanText(degree))}
            تخصص ${_escapeHtml(_cleanText(specialization))}، خريج سنة
            <span dir="ltr">${_escapeHtml(_cleanText(graduationYear))}</span>
            من ${_escapeHtml(_cleanText(university))}.
          </p>

          <p>
            ولدي خبرة في مجال التدريس تقدر بـ (<span dir="ltr">${_escapeHtml(years)}</span>) سنوات،
            ولدي الرغبة والقدرة الكاملة على أداء هذه المهمة التربوية.
          </p>

          <p class="closing">في انتظار ردكم الإيجابي، تقبلوا مني فائق الاحترام والتقدير.</p>
        </main>

        <footer class="signature">توقيع المعني:</footer>
      </section>
    ''');
  }

  static String _wrapA4Html(String bodyContent) {
    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @page { size: A4 portrait; margin: 0; }
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      background: #ffffff;
      color: #111111;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    body {
      width: 210mm;
      min-height: 297mm;
      font-family: Arial, Tahoma, sans-serif;
      direction: rtl;
    }
    .substitution-page {
      width: 210mm;
      min-height: 297mm;
      padding: 32mm 24mm 22mm 24mm;
      position: relative;
      direction: rtl;
      font-size: 20px;
      line-height: 1.85;
    }
    .top-block {
      display: flex;
      flex-direction: row-reverse;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 36mm;
    }
    .person-block {
      width: 48%;
      text-align: right;
      line-height: 1.7;
      white-space: normal;
    }
    .date-block {
      width: 40%;
      text-align: left;
      line-height: 1.7;
      direction: rtl;
    }
    .substitution-content {
      width: 100%;
      font-size: 21px;
      line-height: 2.05;
      text-align: right;
    }
    .substitution-content p {
      margin: 0 0 11mm 0;
      text-align: justify;
      text-align-last: right;
      direction: rtl;
      unicode-bidi: plaintext;
    }
    .recipient {
      text-align: center !important;
      text-align-last: center !important;
      font-weight: 500;
      margin-bottom: 18mm !important;
    }
    .subject {
      text-align: center !important;
      text-align-last: center !important;
      margin-bottom: 16mm !important;
    }
    .closing {
      text-align: center !important;
      text-align-last: center !important;
      margin-top: 6mm !important;
    }
    .signature {
      position: absolute;
      left: 24mm;
      bottom: 42mm;
      font-size: 20px;
      direction: rtl;
    }
    .simple-title {
      width: 210mm;
      padding: 28mm 22mm 8mm;
      font-size: 26px;
      font-weight: 700;
      text-align: center;
    }
    .simple-table {
      width: 166mm;
      margin: 0 auto;
      border-collapse: collapse;
      direction: rtl;
      font-size: 18px;
    }
    .simple-table th, .simple-table td {
      border: 1px solid #dddddd;
      padding: 10px 12px;
      text-align: right;
      vertical-align: top;
    }
    .simple-table th { width: 38%; background: #f4f4f4; }
    .text-template {
      width: 166mm;
      margin: 0 auto;
      font-size: 20px;
      line-height: 1.9;
      white-space: pre-wrap;
      direction: rtl;
      text-align: right;
    }
  </style>
</head>
<body>
$bodyContent
</body>
</html>
''';
  }

  static String _joinClean(List<String> values, {required String separator}) {
    return values.map(_cleanText).where((value) => value.isNotEmpty).join(separator);
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e]'), '')
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _textToHtml(String text) {
    return _escapeHtml(_cleanText(text)).replaceAll('\n', '<br>');
  }

  static String _safeFileName(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    return cleaned.isEmpty ? 'IDARA_DZ' : cleaned;
  }
}
