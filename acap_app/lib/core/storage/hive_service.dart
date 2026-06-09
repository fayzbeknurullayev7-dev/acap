import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

class HiveService {
  HiveService._();

  // Tokens live in the OS keystore (secure), not in Hive boxes.
  static const _secure = FlutterSecureStorage();

  static Future<String?> getAccessToken() =>
      _secure.read(key: AppConstants.accessToken);

  static Future<String?> getRefreshToken() =>
      _secure.read(key: AppConstants.refreshToken);

  static Future<void> setAccessToken(String token) =>
      _secure.write(key: AppConstants.accessToken, value: token);

  static Future<void> clearTokens() async {
    await _secure.delete(key: AppConstants.accessToken);
    await _secure.delete(key: AppConstants.refreshToken);
  }

  static Future<void> init() async {
    await Hive.openBox<dynamic>(AppConstants.userBox);
    await Hive.openBox<dynamic>(AppConstants.settingsBox);
    await Hive.openBox<dynamic>(AppConstants.projectsBox);
  }

  static Box<dynamic> get userBox =>
      Hive.box<dynamic>(AppConstants.userBox);

  static Box<dynamic> get settingsBox =>
      Hive.box<dynamic>(AppConstants.settingsBox);

  static Box<dynamic> get projectsBox =>
      Hive.box<dynamic>(AppConstants.projectsBox);

  static Future<void> clearAll() async {
    await userBox.clear();
    await settingsBox.clear();
    await projectsBox.clear();
  }
}
