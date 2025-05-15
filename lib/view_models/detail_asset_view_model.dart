import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class DetailAssetViewModel extends ChangeNotifier {
  String? imageUrl;
  bool isLoading = true;
  String? errorMessage;

  // API constant untuk membentuk URL gambar

  Future<void> loadImage(String assetImage) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      debugPrint('[ViewModel] Memulai load image: $assetImage');

      if (assetImage.isEmpty) {
        errorMessage = 'Asset image name is empty';
        imageUrl = null;
        debugPrint('[ViewModel] Gagal: Nama file kosong');
      } else {
        // Gunakan API constant untuk membentuk URL gambar
        imageUrl = ApiConstants.viewAssetImg(assetImage);
        debugPrint('[ViewModel] URL image yang dihasilkan: $imageUrl');
      }
    } catch (e) {
      errorMessage = 'Failed to load image: $e';
      imageUrl = null;
      debugPrint('[ViewModel] Exception: $e');
    } finally {
      isLoading = false;
      notifyListeners();
      debugPrint('[ViewModel] Selesai loading image.');
    }
  }
}