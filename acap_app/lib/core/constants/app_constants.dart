import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // API — dev/prod switch (kDebugMode = true while debugging)
  static const _devBase  = 'http://10.0.2.2:8000/api/v1'; // Android emulator → host
  static const _prodBase = 'https://api.acap.dev/api/v1';
  static const _devWs    = 'ws://10.0.2.2:8000/ws';
  static const _prodWs   = 'wss://api.acap.dev/ws';

  static String get baseUrl => kDebugMode ? _devBase : _prodBase;
  static String get wsUrl   => kDebugMode ? _devWs   : _prodWs;

  // Per-service URLs (microservices). dev → Android emulator host bridge.
  static String get authUrl =>
      kDebugMode ? 'http://10.0.2.2:8000' : 'https://auth.acap.dev';
  static String get projectsUrl =>
      kDebugMode ? 'http://10.0.2.2:8002' : 'https://projects.acap.dev';
  static String get filesUrl =>
      kDebugMode ? 'http://10.0.2.2:8004' : 'https://files.acap.dev';
  static String get terminalUrl =>
      kDebugMode ? 'http://10.0.2.2:8003' : 'https://terminal.acap.dev';
  static String get agentUrl =>
      kDebugMode ? 'http://10.0.2.2:8001' : 'https://agent.acap.dev';
  static String get agentWsUrl =>
      kDebugMode ? 'ws://10.0.2.2:8001' : 'wss://agent.acap.dev';
  static String get terminalWsUrl =>
      kDebugMode ? 'ws://10.0.2.2:8003' : 'wss://terminal.acap.dev';

  static const apiTimeout   = Duration(seconds: 30);
  static const wsReconnect  = Duration(seconds: 3);

  // Storage keys
  static const accessToken  = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userBox      = 'user_box';
  static const settingsBox  = 'settings_box';
  static const projectsBox  = 'projects_box';

  // Limits
  static const otpLength    = 6;
  static const otpTtlSec    = 300; // 5 min
  static const maxFileSize  = 10 * 1024 * 1024; // 10 MB

  // Pagination
  static const pageSize     = 20;

  // Animation durations
  static const animFast     = Duration(milliseconds: 150);
  static const animMedium   = Duration(milliseconds: 300);
  static const animSlow     = Duration(milliseconds: 500);
}
