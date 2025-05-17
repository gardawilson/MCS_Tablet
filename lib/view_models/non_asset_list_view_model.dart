import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/not_asset_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'dart:io';


class NoAssetViewModel extends ChangeNotifier {
  List<NonAssetItem> _items = [];
  bool _isLoading = false;
  File? _selectedImage;

  bool isImageChanged = false;

  List<NonAssetItem> get items => _items;
  bool get isLoading => _isLoading;
  File? get selectedImage => _selectedImage;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchNonAssetItems(String noso) async {
    try {
      _isLoading = true;

      final url = Uri.parse(ApiConstants.listNonAsset(noso));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        _items = data.map((item) => NonAssetItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching no asset items: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> addNonAsset({  // <-- Ubah di sini
    required String noSO,
    required String imageName,
    required String locationCode,
    required String nonAssetName,
    required String remark,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final response = await http.post(
        Uri.parse('http://192.168.11.153:6000/api/no-asset-stock-opname/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "NoSO": noSO,
          "image": imageName,
          "location_code": locationCode,
          "non_asset_name": nonAssetName,
          "remark": remark,
        }),
      );

      if (response.statusCode == 201) {
        _selectedImage = null;
        await fetchNonAssetItems(noSO);
        return true;  // <-- Sekarang valid
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
      return false;  // <-- Return false jika gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> deleteSelectedItems(List<int> ids) async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final response = await http.post(
        Uri.parse('http://192.168.11.153:6000/api/no-asset-stock-opname/DELETE'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "idAssets": ids.map((id) => id.toString()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete items: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting selected items: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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



  Future<bool> updateNonAsset({
    required int idNonAsset,
    required String image,
    required String locationCode,
    required String nonAssetName,
    required String? remark,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final response = await http.put(
        Uri.parse('http://192.168.11.153:6000/api/no-asset-stock-opname/update/$idNonAsset'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "image": image,
          "location_code": locationCode,
          "non_asset_name": nonAssetName,
          "remark": remark,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Update failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating no asset item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }
}