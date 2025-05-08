import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_opname_model.dart';
import '../models/next_noso_model.dart';
import '../constants/api_constants.dart';


class StockOpnameViewModel extends ChangeNotifier {
  List<StockOpname> _stockOpnameList = [];
  bool _isLoading = false;
  String _errorMessage = '';


  List<StockOpname> get stockOpnameList => _stockOpnameList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fungsi untuk mengambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Mengambil token yang disimpan
  }

  // Fungsi untuk mengambil data stock opname
  Future<void> fetchStockOpname() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ambil token dari SharedPreferences
      String? token = await _getToken();

      if (token == null) {
        _errorMessage = 'No token found';
        _stockOpnameList = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.listNoSO),
        headers: {
          'Authorization': 'Bearer $token', // Menambahkan token di header Authorization
        },
      );

      if (response.statusCode == 200) {
        // Parsing data jika status code OK (200)
        List<dynamic> data = json.decode(response.body);
        _stockOpnameList = data.map((item) => StockOpname.fromJson(item)).toList();
        _errorMessage = '';  // Kosongkan pesan error jika sukses
      } else if (response.statusCode == 401) {
        // Jika token tidak valid atau kadaluarsa
        _errorMessage = 'Unauthorized: Token is invalid or expired';
        _stockOpnameList = [];
      } else {
        // Jika status code bukan 200 atau 401, coba ambil pesan error dari API
        final responseBody = json.decode(response.body);
        _errorMessage = responseBody['message'] ?? 'Tidak ada Jadwal Stock Opname saat ini';
        _stockOpnameList = [];
      }
    } catch (error) {
      // Menangani kesalahan koneksi
      _errorMessage = 'Failed to connect to the server';
      _stockOpnameList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi POST untuk mengirim data stock opname
  Future<bool> submitStockOpname({
    required String tanggal,
    required List<String> idCompanies,
    required List<String> idCategories,
    required List<String> idLocations,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Ambil token dari SharedPreferences
      String? token = await _getToken();
      if (token == null) {
        _errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Buat body JSON
      final body = {
        "Tanggal": tanggal,
        "IdCompanies": idCompanies,
        "IdCategories": idCategories,
        "IdLocations": idLocations,
      };

      // Lakukan POST request
      final response = await http.post(
        Uri.parse(ApiConstants.addNoSO), // Ganti dengan endpoint API POST Anda
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Jika sukses
        _errorMessage = '';
        return true;
      } else {
        // Jika terjadi error
        final responseBody = json.decode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to submit stock opname';
        return false;
      }
    } catch (error) {
      _errorMessage = 'Failed to connect to the server';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // Delete NoSO items - Updated version
  Future<void> deleteStockOpname(String noSO) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? token = await _getToken();

      if (token == null) {
        _errorMessage = 'No token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Wrap the noSO in an array to match backend expectation
      final requestBody = {'NoSO': [noSO]};
      print('JSON yang dikirim: ${jsonEncode(requestBody)}');  // Debug line

      final response = await http.delete(
        Uri.parse(ApiConstants.deleteNoSO),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'NoSO': [noSO]}), // Now sending as array
      );

      if (response.statusCode == 200) {
        // Hapus item dari _stockOpnameList jika sukses
        _stockOpnameList.removeWhere((item) => item.noSO == noSO);
        _errorMessage = '';

        // Optional: Fetch fresh data from server
        await fetchStockOpname();
      } else {
        final responseBody = json.decode(response.body);
        _errorMessage = responseBody['message'] ?? 'Gagal menghapus data';
        print('Error response: ${response.body}');
      }
    } catch (error) {
      _errorMessage = 'Failed to connect to the server: ${error.toString()}';
      print('Error details: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

  }

}
