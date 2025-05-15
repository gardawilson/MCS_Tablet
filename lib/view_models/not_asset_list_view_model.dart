import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/not_asset_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'dart:io';


class NoAssetViewModel extends ChangeNotifier {
  List<NoAssetItem> _items = [];
  bool _isLoading = false;
  File? _selectedImage;

  List<NoAssetItem> get items => _items;
  bool get isLoading => _isLoading;
  File? get selectedImage => _selectedImage;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchNoAssetItems(String noso) async {
    try {
      _isLoading = true;

      final url = Uri.parse(ApiConstants.listAdditionalAsset(noso));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        _items = data.map((item) => NoAssetItem.fromJson(item)).toList();
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

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      rethrow;
    }
  }

  Future<String?> uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token not found");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.uploadImg),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile(
          'image',
          _selectedImage!.readAsBytes().asStream(),
          _selectedImage!.lengthSync(),
          filename: _selectedImage!.path.split('/').last,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['fileName'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<bool> addNotAsset({  // <-- Ubah di sini
    required String noSO,
    required String imageName,
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
          "remark": remark,
        }),
      );

      if (response.statusCode == 201) {
        _selectedImage = null;
        await fetchNoAssetItems(noSO);
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


  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }
}