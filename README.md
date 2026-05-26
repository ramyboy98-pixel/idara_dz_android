# IDARA DZ Android

نسخة Android حقيقية أولية لتطبيق IDARA DZ مبنية بـ Flutter.

## التشغيل

```bash
flutter pub get
flutter run
```

## البناء APK

```bash
flutter build apk --release
```

النسخة الحالية هي المرحلة الأولى: الهيكل، الثيم، الواجهات الرئيسية، وقاعدة بيانات أولية.

## البناء عبر GitHub Actions

هذا المشروع مجهز ليتم بناؤه من الهاتف فقط عبر GitHub Actions.

### طريقة الحصول على APK

1. ارفع ملفات المشروع إلى GitHub بحيث يكون `pubspec.yaml` في جذر المستودع.
2. افتح تبويب **Actions** داخل GitHub.
3. اختر workflow باسم **Build Android APK**.
4. اضغط **Run workflow**.
5. بعد انتهاء البناء، افتح آخر تشغيل ناجح.
6. من قسم **Artifacts** حمّل الملف:
   `IDARA-DZ-release-apk`

الملف الناتج يحتوي على:
`app-release.apk`

### ملاحظة

الـ APK في هذه المرحلة غير موقّع بتوقيع نشر رسمي على Google Play. هو مناسب للتجربة والتثبيت اليدوي. لاحقًا نضيف signing config وملف keystore عند الوصول لمرحلة النشر.


## GitHub Actions notes

The workflow creates Android platform files automatically, then removes the default Flutter `test/` folder before running `flutter analyze`. This prevents the generated sample `widget_test.dart` from failing analysis before we add real tests later.


## قرار نسخة Android

نسخة Android لا تستعمل الطباعة المباشرة. النظام المعتمد هو:

1. إنشاء الوثيقة داخل التطبيق.
2. تصديرها كملف PDF.
3. حفظ مسار PDF في الأرشيف.
4. مشاركة ملف PDF أو فتحه من الهاتف عند الحاجة.

ملف التصدير الأساسي:

```text
lib/core/pdf/pdf_exporter.dart
```


## المرحلة الحالية

تمت إضافة صفحة **طلب خطي** داخل قسم وثائق، وتحتوي على بطاقات نماذج أولية:

- طلب توظيف 1
- طلب توظيف 2
- مسابقة الجمارك
- مسابقة الشرطة
- مسابقة الحماية المدنية
- عقود ما قبل التشغيل
- مسابقة الماستر

المرحلة التالية: فتح نموذج طلب توظيف 1 وإضافة حقول الإدخال ثم تصدير PDF.


## ملاحظة إصلاح الاعتماديات
تم ضبط `file_picker` على النسخة `^8.0.7` حتى لا يحدث تعارض مع `share_plus ^9.0.0` أثناء البناء عبر GitHub Actions.
