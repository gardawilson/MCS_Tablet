import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../view_models/stock_opname_input_view_model.dart';


class AttachmentSOViewModel extends ChangeNotifier {
  // Variabel untuk menyimpan gambar yang dipilih
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  // Menambahkan state loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi untuk mengatur state loading
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fungsi untuk mengambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Mengambil token yang disimpan
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Fungsi untuk mengirim attachment (update SO)
  Future<void> sendAttachment({
    required String noSO,
    required String assetCode,
    required String status,
    required String statusName,
    required String imageName,
    required StockOpnameInputViewModel stockOpnameViewModel, // Dikirim dari luar
  }) async {
    setLoading(true); // Tampilkan loading
    try {
      // Mendapatkan token dari SharedPreferences
      String? token = await _getToken();
      String? user = await getUsername();

      if (token == null) {
        throw Exception("Token tidak ditemukan. Pastikan pengguna telah login.");
      }

      if (user == null) {
        throw Exception("Username tidak ditemukan. Pastikan pengguna telah login.");
      }

      // URL endpoint API untuk update SO
      final url = Uri.parse(ApiConstants.updateSO);

      // Header untuk request
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Body untuk request
      final body = jsonEncode({
        'noSO': noSO,
        'assetCode': assetCode,
        'image': imageName,
        'idStatus': status,
      });

      // Mengirim request HTTP PUT untuk update SO
      final response = await http.put(url, headers: headers, body: body);

      // Cek status response
      if (response.statusCode == 200) {
        // Update state di StockOpnameInputViewModel
        stockOpnameViewModel.updateAssetBefore(
          assetCode,
          hasBeenPrinted: 1,
          newStatus: statusName, // atau bisa kamu mapping ke string lain
          assetImage: imageName,
          username: user,  // Hanya kirim jika user tidak null
        );
        print('✅ Attachment submitted successfully!');
      } else {
        print('❌ Failed to submit attachment. Status code: ${response.statusCode}');
        print('📝 Response: ${response.body}');
        throw Exception('Failed to submit attachment');
      }
    } catch (e, stackTrace) {
      print('🔥 Terjadi kesalahan saat mengirim attachment: $e');
      print('📍 Stacktrace: $stackTrace');
    } finally {
      setLoading(false); // Sembunyikan loading
    }
  }


  // Fungsi untuk memilih gambar menggunakan kamera
  Future<void> pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners(); // Notifikasi perubahan pada gambar yang dipilih
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  // Fungsi untuk mengupload gambar ke server
  Future<String?> uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      // Mendapatkan token dari SharedPreferences
      String? token = await _getToken();
      if (token == null) {
        throw Exception("Token tidak ditemukan!");
      }

      // Membuat request untuk mengupload gambar
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.uploadImg),
      );

      // Tambahkan header Authorization ke request
      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan file gambar ke request
      request.files.add(
        http.MultipartFile(
          'image',
          _selectedImage!.readAsBytes().asStream(),
          _selectedImage!.lengthSync(),
          filename: _selectedImage!.path.split('/').last,
        ),
      );

      // Mengirim request upload gambar
      final response = await request.send();

      // Mengecek status code dari response
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['fileName']; // Mengembalikan nama file yang diupload
      } else {
        debugPrint('❌ Gagal mengupload gambar. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

}
