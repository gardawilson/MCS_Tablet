import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get wsUrl => dotenv.env['WS_BASE_URL'] ?? _defaultWsUrl;

  // Helper untuk menentukan WS URL default berdasarkan baseUrl
  static String get _defaultWsUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
  }

  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/login';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String get masterCompany => '$baseUrl/api/master-company';
  static String get addNoSO => '$baseUrl/api/no-stock-opname/create';
  static String get deleteNoSO => '$baseUrl/api/no-stock-opname/delete';
  static String scanAsset(String noSO) => '$baseUrl/api/no-stock-opname/$noSO';
  static String listAssets(String selectedNoSO) => '$baseUrl/api/no-stock-opname/$selectedNoSO';
  static String listAssetsBefore(String selectedNoSO) => '$baseUrl/api/no-stock-opname-current/$selectedNoSO';

  // WebSocket Endpoint (new)
  static String realtimeStockOpname(String noSO) {
    return '$wsUrl/ws-stock-opname?noso=$noSO}';
  }
}
