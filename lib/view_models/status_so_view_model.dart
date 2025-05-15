import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/status_so_model.dart';
import 'package:flutter/material.dart';


class StatusSOViewModel extends ChangeNotifier {

  bool isLoading = false;
  String errorMessage = '';
  List<StatusSO> statuses = []; // Tambahkan daftar untuk menyimpan data status


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

  Future<void> fetchStatuses({bool notify = true}) async {
    try {
      if (notify) {
        isLoading = true;
        notifyListeners();
      }

      print('Fetching statuses from API: ${ApiConstants.listStatusSO}');

      final response = await http.get(
        Uri.parse(ApiConstants.listStatusSO),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('API Response (statusCode: ${response.statusCode}): ${response.body}');

        final List<dynamic> jsonData = json.decode(response.body)['data'];
        print('Decoded JSON Data: $jsonData'); // Log data mentah dari API

        statuses = jsonData.map((e) {
          final status = StatusSO.fromJson(e);
          print('Parsed Status Item -> ID: ${status.id}, Status: ${status.status}');
          return status;
        }).toList();

        print('Successfully fetched ${statuses.length} statuses.');
        errorMessage = '';
      } else {
        errorMessage = 'Failed to load statuses (${response.statusCode})';
        print(errorMessage);
      }
    } catch (e) {
      errorMessage = 'Error: $e';
      print(errorMessage);
    } finally {
      if (notify) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteStatus(int id) async {
    try {
      isLoading = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.delete(
        Uri.parse(ApiConstants.deleteStatusSO(id)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Hapus dari list lokal
        statuses.removeWhere((status) => status.id == id);
        notifyListeners();
        print('✅ Status berhasil dihapus.');
      } else {
        print('❌ Gagal menghapus status (${response.statusCode}).');
      }
    } catch (e) {
      print('🔥 Error saat menghapus status: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> updateStatus(int id, String newStatus) async {
    try {
      isLoading = true;
      notifyListeners();

      final token = await _getToken();

      final response = await http.put(
        Uri.parse(ApiConstants.updateStatusSO(id)), // pastikan endpoint update benar
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),  // kirim data status baru
      );

      if (response.statusCode == 200) {
        // Update list lokal
        final index = statuses.indexWhere((status) => status.id == id);
        if (index != -1) {
          statuses[index] = statuses[index].copyWith(status: newStatus); // Asumsi ada method copyWith
          notifyListeners();
        }
        print('✅ Status berhasil diperbarui.');
      } else {
        print('❌ Gagal memperbarui status (${response.statusCode}).');
      }
    } catch (e) {
      print('🔥 Error saat memperbarui status: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



}