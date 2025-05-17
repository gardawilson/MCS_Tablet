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

  bool isImageChanged = false;


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
    required bool isUpdateValid,
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
        'isUpdateValid': isUpdateValid,
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
          hasBeenPrinted: isUpdateValid ? 1 : 0,
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
        isImageChanged = true; // ✅ tandai bahwa gambar telah diubah
        notifyListeners(); // Notifikasi perubahan pada gambar yang dipilih
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  // Fungsi untuk mengupload gambar ke server
  Future<String?> uploadImage(String noSO) async {
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

      // Tambahkan nilai noSO ke dalam form-data
      request.fields['noSO'] = noSO;

      // Tambahkan file gambar ke request
      request.files.add(
        http.MultipartFile(
          'image',
          _selectedImage!.readAsBytes().asStream(),
          _selectedImage!.lengthSync(),
          filename: _selectedImage!.path.split('/').last,
        ),
      );

      // Kirim request upload gambar
      final response = await request.send();

      // Mengecek status code dari response
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['fileName'];
      } else {
        debugPrint('❌ Gagal mengupload gambar. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }


  Future<String?> replaceImage({
    required String oldImageName,
    required String noSO,
  }) async {
    if (_selectedImage == null) {
      debugPrint('[replaceImage] Tidak ada gambar yang dipilih (_selectedImage == null).');
      return null;
    }

    try {
      debugPrint('[replaceImage] Mulai proses upload gambar pengganti.');
      String? token = await _getToken();
      if (token == null) {
        debugPrint('[replaceImage] Token tidak ditemukan!');
        throw Exception("Token tidak ditemukan!");
      }
      debugPrint('[replaceImage] Token berhasil didapatkan.');

      final uri = Uri.parse(ApiConstants.editAssetImg);
      debugPrint('[replaceImage] Endpoint URI: $uri');
      debugPrint('[replaceImage] Nama file lama: $oldImageName');
      debugPrint('[replaceImage] noSO: $noSO');
      debugPrint('[replaceImage] Nama file baru: ${_selectedImage!.path.split('/').last}');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Kirimkan oldImageName dan noSO sebagai fields
      request.fields['oldImageName'] = oldImageName;
      request.fields['noSO'] = noSO;

      // Tambahkan file gambar baru
      request.files.add(
        http.MultipartFile(
          'image',
          _selectedImage!.readAsBytes().asStream(),
          _selectedImage!.lengthSync(),
          filename: _selectedImage!.path.split('/').last,
        ),
      );

      debugPrint('[replaceImage] Mengirim request multipart dengan gambar baru...');
      final response = await request.send();

      debugPrint('[replaceImage] Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        debugPrint('[replaceImage] Response data: $responseData');
        final jsonResponse = json.decode(responseData);
        debugPrint('[replaceImage] Upload berhasil, fileName baru: ${jsonResponse['fileName']}');
        return jsonResponse['fileName'];
      } else {
        debugPrint('❌ [replaceImage] Gagal mengganti gambar. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e, stacktrace) {
      debugPrint('🔥 [replaceImage] Error mengganti gambar: $e');
      debugPrint('Stacktrace:\n$stacktrace');
      return null;
    }
  }




}
