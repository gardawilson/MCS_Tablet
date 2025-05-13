import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:smb_connect/smb_connect.dart';

class DetailAssetViewModel extends ChangeNotifier {
  Uint8List? imageBytes;
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadImage(String assetImage) async {
    const String share = "Temp";
    const String remoteFolder = "/Garda/mcs_attachment";

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final connect = await SmbConnect.connectAuth(
        host: "192.168.10.100",
        domain: "",
        username: "rduser5",
        password: "Utama1234",
      );

      final filePath = '/$share$remoteFolder/$assetImage';

      // Membaca file sebagai byte array
      imageBytes = await readFileFromSmb(connect, filePath);
      if (imageBytes == null) {
        throw Exception("Failed to read file from SMB");
      }

      await connect.close();
    } catch (e) {
      errorMessage = 'Failed to load image: $e';
      imageBytes = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> readFileFromSmb(SmbConnect connect, String filePath) async {
    try {
      // Buka file dari SMB server
      final file = await connect.createFile(filePath); // Ini akan gagal jika file tidak ada
      final List<int> fileBytes = [];
      final Stream<List<int>> fileStream = await connect.openRead(file);

      await for (final chunk in fileStream) {
        fileBytes.addAll(chunk); // Gabungkan byte ke dalam array
      }

      return Uint8List.fromList(fileBytes);
    } catch (e) {
      print('Error reading file: $e');
      return null; // Return null jika file tidak ditemukan atau terjadi error
    }
  }

}