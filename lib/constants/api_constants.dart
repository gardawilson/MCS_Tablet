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
  static String get addStatusSO => '$baseUrl/api/status';
  static String get listStatusSO => '$baseUrl/api/status';
  static String get deleteNoSO => '$baseUrl/api/no-stock-opname/delete';
  static String get updateSO => '$baseUrl/api/update-stock-opname';
  static String get uploadImg => '$baseUrl/api/upload-image';
  static String get editAssetImg => '$baseUrl/api/edit-image';
  static String get addNonAsset => '$baseUrl/api/no-asset-stock-opname/create';
  static String get deleteNonAsset => '$baseUrl/api/no-asset-stock-opname/delete';
  static String updateNonAsset(int idNonAsset) => '$baseUrl/api/no-asset-stock-opname/update/$idNonAsset';
  static String viewAssetImg(String imgName) => '$baseUrl/api/upload/$imgName';
  static String deleteStatusSO(int idstatus) => '$baseUrl/api/status/$idstatus';
  static String updateStatusSO(int idstatus) => '$baseUrl/api/status/$idstatus';
  static String listNonAsset(String noso) => '$baseUrl/api/no-asset-stock-opname/$noso';
  static String scanAsset(String noSO) => '$baseUrl/api/no-stock-opname/$noSO';
  static String listAssets(String selectedNoSO) => '$baseUrl/api/no-stock-opname/$selectedNoSO';
  static String listAssetsBefore(String selectedNoSO) => '$baseUrl/api/no-stock-opname-current/$selectedNoSO';
  static String reportSO(String selectedNoSO) => '$baseUrl/api/report/$selectedNoSO/pdf';

  // WebSocket Endpoint (new)
  static String realtimeStockOpname(String noSO) {
    return '$wsUrl/ws-stock-opname?noso=$noSO}';
  }
}
