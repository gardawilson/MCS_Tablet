import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';



class StatusSOViewModel {

  // Fungsi untuk mengambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Mengambil token yang disimpan
  }

  Future<void> sendStatus(String status) async {
    try {
      String? token = await _getToken();
      final url = Uri.parse(ApiConstants.addStatusSO);

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'status': status});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Status berhasil dikirim!');
      } else {
        print('❌ Gagal mengirim status.');
      }
    } catch (e, stackTrace) {
      print('🔥 Terjadi kesalahan saat mengirim status: $e');
      print('📍 Stacktrace: $stackTrace');
    }
  }

}