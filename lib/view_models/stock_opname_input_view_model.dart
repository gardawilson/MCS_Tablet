import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/asset_after_model.dart';
import '../models/asset_before_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class StockOpnameInputViewModel extends ChangeNotifier {

  // WebSocket
  WebSocketChannel? _channel;
  String? _currentNoSO; // Untuk reconnect

  String errorMessageAfter = '';
  bool isLoadingAfter = false;
  bool isFetchingMoreAfter = false;
  bool hasMoreAfter = true;
  int currentOffsetAfter = 0;
  final int limitAfter = 20; // Sesuaikan dengan limit di backend
  int totalAssetsAfter = 0; // total semua data dari backend
  List<AssetAfterModel> assetListAfter = [];


  String errorMessageBefore = '';
  bool isLoadingBefore = false;
  bool isFetchingMoreBefore = false;
  bool hasMoreBefore = true;
  int currentOffsetBefore = 0;
  final int limitBefore = 20; // Sesuaikan dengan limit di backend
  int totalAssetsBefore = 0; // total semua data dari backend
  List<AssetBeforeModel> assetListBefore = [];


  // Fungsi untuk mengambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 5. Cleanup
  Future<void> _disconnectWebSocket() async {
    await _channel?.sink?.close();
    _channel = null;
  }

  // 3. Handler untuk update real-time
  void _handleRealtimeUpdate(dynamic data) {
    try {
      final payload = jsonDecode(data);

      // Pastikan tipe pesan adalah 'NEW_ASSET'
      if (payload['type'] == 'NEW_ASSET') {
        final newAsset = AssetAfterModel.fromJson(payload['data']);

        final noso = payload['data']['NoSO'];

        // Validasi apakah NoSO dari pesan sama dengan _currentNoSO
        if (noso != _currentNoSO) {
          print('⚠️ Pesan dari NoSO berbeda diabaikan: $noso');
          return; // Abaikan pesan jika NoSO tidak cocok
        }

        // Cek duplikasi
        final exists = assetListAfter.any((a) => a.assetCode == newAsset.assetCode);

        if (!exists) {
          // Tambahkan ke awal list
          assetListAfter.insert(0, newAsset);
          totalAssetsAfter += 1;

          // Hapus asset dengan assetCode yang sama dari assetListBefore
          assetListBefore.removeWhere((a) => a.assetCode == newAsset.assetCode);
          totalAssetsBefore -= 1;

          // Update pagination offset jika perlu
          if (!isFetchingMoreAfter) {
            currentOffsetAfter += 1;
          }

          if (!isFetchingMoreBefore) {
            currentOffsetBefore -= 1;
          }

          notifyListeners();
          print('🆕 Real-time update: ${newAsset.assetCode}');
        }
      }
    } catch (e) {
      print('❌ Error processing WS message: $e');
    }
  }

  // 2. Inisialisasi WebSocket
  Future<void> _initWebSocket(String noSO) async {
    await _disconnectWebSocket(); // Tutup koneksi sebelumnya
    _currentNoSO = noSO;

    try {
      final wsUrl = ApiConstants.realtimeStockOpname(noSO);

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl))
        ..stream.listen(
          _handleRealtimeUpdate,
          onError: (error) => print('WebSocket Error: $error'),
        );

      print('🔄 WebSocket Connected for NoSO: $noSO');
    } catch (e) {
      print('❌ WebSocket Connection Failed: $e');
    }
  }


  Future<void> fetchAssetsAfter(String selectedNoSO, {bool loadMore = false, List<String>? companyFilters, List<String>? categoryFilters, List<String>? locationFilters}) async {
    if (!loadMore) {

      // Reset state untuk load baru
      isLoadingAfter = true;
      currentOffsetAfter = 0;
      hasMoreAfter = true;
      assetListAfter.clear();
    } else {
      // Set flag fetching more untuk load tambahan
      isFetchingMoreAfter = true;
    }

    errorMessageAfter = '';
    notifyListeners();

    print("📡 Fetching assets for NoSO: $selectedNoSO, offset: $currentOffsetAfter");

    try {
      final uri = Uri.parse('${ApiConstants.listAssets(selectedNoSO)}').replace(
        queryParameters: {
          'offset': '$currentOffsetAfter',
          if (companyFilters != null && companyFilters.isNotEmpty)
            'company': companyFilters.join(','),
          if (categoryFilters != null && categoryFilters.isNotEmpty)
            'category': categoryFilters.join(','),
          if (locationFilters != null && locationFilters.isNotEmpty)
            'location': locationFilters.join(','),
        },
      );

      String? token = await _getToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> jsonData = responseData['data'];

        final newAssets = jsonData.map((json) => AssetAfterModel.fromJson(json)).toList();

        if (loadMore) {
          assetListAfter.addAll(newAssets);
        } else {
          assetListAfter = newAssets;
        }

        // ✅ Ambil total dari backend
        totalAssetsAfter = responseData['total'] ?? 0;

        // Update pagination state
        currentOffsetAfter = responseData['nextOffset'] ?? currentOffsetAfter + newAssets.length;
        hasMoreAfter = responseData['hasMore'] ?? (newAssets.length == limitAfter);

        errorMessageAfter = '';
        print("✅ Data berhasil dimuat: $totalAssetsAfter} assets");
      } else {
        totalAssetsAfter = 0;
        errorMessageAfter = 'Gagal memuat data (${response.statusCode})';
      }
    } catch (e) {
      errorMessageAfter = 'Terjadi kesalahan: $e';
    } finally {
      isLoadingAfter = false;
      isFetchingMoreAfter = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssetsBefore(String selectedNoSO, {bool loadMore = false, List<String>? companyFilters, List<String>? categoryFilters, List<String>? locationFilters}) async {
    if (!loadMore) {

      // Initialize WebSocket hanya saat load pertama
      _initWebSocket(selectedNoSO);

      // Reset state untuk load baru
      isLoadingBefore = true;
      currentOffsetBefore = 0;
      hasMoreBefore = true;
      assetListBefore.clear();
    } else {
      // Set flag fetching more untuk load tambahan
      isFetchingMoreBefore = true;
    }

    errorMessageBefore = '';
    notifyListeners();

    print("📡 Fetching assets for NoSO: $selectedNoSO, offset: $currentOffsetBefore");

    try {
      final uri = Uri.parse('${ApiConstants.listAssetsBefore(selectedNoSO)}').replace(
        queryParameters: {
          'offset': '$currentOffsetBefore',
          if (companyFilters != null && companyFilters.isNotEmpty)
            'company': companyFilters.join(','),
          if (categoryFilters != null && categoryFilters.isNotEmpty)
            'category': categoryFilters.join(','),
          if (locationFilters != null && locationFilters.isNotEmpty)
            'location': locationFilters.join(','),
        },
      );

      String? token = await _getToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> jsonData = responseData['data'];

        final newAssets = jsonData.map((json) => AssetBeforeModel.fromJson(json)).toList();

        if (loadMore) {
          assetListBefore.addAll(newAssets);
        } else {
          assetListBefore = newAssets;
        }

        // ✅ Ambil total dari backend
        totalAssetsBefore = responseData['total'] ?? 0;

        // Update pagination state
        currentOffsetBefore = responseData['nextOffset'] ?? currentOffsetBefore + newAssets.length;
        hasMoreBefore = responseData['hasMore'] ?? (newAssets.length == limitBefore);

        errorMessageBefore = '';
        print("✅ Data berhasil dimuat: $totalAssetsBefore} assets");
      } else {
        totalAssetsBefore = 0;
        errorMessageBefore = 'Gagal memuat data (${response.statusCode})';
      }
    } catch (e) {
      errorMessageBefore = 'Terjadi kesalahan: $e';
    } finally {
      isLoadingBefore = false;
      isFetchingMoreBefore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreAssetsAfter(String selectedNoSO, {List<String>? companyFilters, List<String>? categoryFilters, List<String>? locationFilters}) async {
    if (!hasMoreAfter || isFetchingMoreAfter) return;
    await fetchAssetsAfter(selectedNoSO, loadMore: true, companyFilters: companyFilters, categoryFilters: categoryFilters, locationFilters: locationFilters);
  }

  Future<void> loadMoreAssetsBefore(String selectedNoSO, {List<String>? companyFilters, List<String>? categoryFilters, List<String>? locationFilters}) async {
    if (!hasMoreBefore || isFetchingMoreBefore) return;
    await fetchAssetsBefore(selectedNoSO, loadMore: true, companyFilters: companyFilters, categoryFilters: categoryFilters, locationFilters: locationFilters);
  }


  //STATE UNTUK UPDATE DATA ASSETBEFORE
  void updateAssetBefore(String assetCode, {
    required int hasBeenPrinted,
    required String assetImage,
    required String username,
    String? newStatus,
  }) {
    final index = assetListBefore.indexWhere((a) => a.assetCode == assetCode);
    if (index != -1) {
      final oldAsset = assetListBefore[index];
      assetListBefore[index] = AssetBeforeModel(
        assetCode: oldAsset.assetCode,
        assetName: oldAsset.assetName,
        hasNotBeenPrinted: hasBeenPrinted,
        assetImage: assetImage,
        username: username.toString().toUpperCase(),
        statusSO: newStatus ?? oldAsset.statusSO,
      );
      notifyListeners(); // Trigger UI refresh
      print('✅ Asset updated: $assetCode');
    } else {
      print('⚠️ Asset not found: $assetCode');
    }
  }


  @override
  void dispose() {
    _disconnectWebSocket();
    super.dispose();
  }
}