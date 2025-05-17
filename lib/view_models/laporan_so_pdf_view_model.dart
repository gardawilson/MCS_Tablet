import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../constants/api_constants.dart';


class ReportViewModel with ChangeNotifier {
  bool _isLoading = false;
  String? _pdfPath;
  String? _error;

  bool get isLoading => _isLoading;
  String? get pdfPath => _pdfPath;
  String? get error => _error;

  Future<void> downloadAndOpenPdf(String noSO) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final url = Uri.parse(ApiConstants.reportSO(noSO));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/Laporan_$noSO.pdf');

        await file.writeAsBytes(response.bodyBytes);

        _pdfPath = file.path;
        notifyListeners();

        final result = await OpenFile.open(file.path, type: 'application/pdf');

        if (result.type != ResultType.done) {
          _error = 'Gagal membuka PDF: ${result.message}';
          debugPrint('Error opening file: ${result.message}');
        }
      } else {
        _error = 'Gagal mengunduh PDF: ${response.statusCode}';
        debugPrint('Download error: Status code ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
      debugPrint('Error details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
