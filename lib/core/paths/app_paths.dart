import 'package:path_provider/path_provider.dart';

class AppPaths {
  static Future<String> appDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}
