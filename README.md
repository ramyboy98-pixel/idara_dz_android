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
