import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:smb_connect/smb_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AttachmentSOViewModel extends ChangeNotifier {
  File? _selectedImage;
  File? get selectedImage => _selectedImage;
  String? selectedStatus;

  bool _isLoading = false; // Menambahkan state loading
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

  // Fungsi untuk mengirim attachment
  Future<void> sendAttachment({
    required String noSO,
    required String assetCode,
    required String status,
    required String imageName,
  }) async {
    setLoading(true); // Tampilkan loading
    try {
      // Mendapatkan token dari SharedPreferences
      String? token = await _getToken();
      if (token == null) {
        throw Exception("Token tidak ditemukan. Pastikan pengguna telah login.");
      }

      // URL endpoint
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

      // Mengirim request HTTP PUT
      final response = await http.put(url, headers: headers, body: body);

      // Cek status response
      if (response.statusCode == 200) {
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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<String?> saveImageToSmbFolder(BuildContext context) async {
    if (_selectedImage == null) return null;

    const String share = "Temp";
    const String remoteFolder = "/Garda/mcs_attachment";
    final String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    SmbConnect? connect;
    IOSink? sink;

    setLoading(true); // Tampilkan loading
    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      connect = await SmbConnect.connectAuth(
        host: "192.168.10.100",
        domain: "",
        username: "rduser5",
        password: "Utama1234",
      );

      final tempPath = '/$share$remoteFolder/$fileName';
      final tempFile = await connect.createFile(tempPath);
      sink = await connect.openWrite(tempFile);

      sink.add(imageBytes);
      await sink.flush();
      await sink.close();
      sink = null;

      return fileName; // Kembalikan nama file
    } catch (e) {
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: ${e.toString()}')),
      );
      return null;
    } finally {
      setLoading(false); // Sembunyikan loading
      await sink?.close();
      await connect?.close();
    }
  }
}