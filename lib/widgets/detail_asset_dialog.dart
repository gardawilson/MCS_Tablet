import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/detail_asset_view_model.dart';
import 'dart:typed_data';


class DetailAssetDialog extends StatelessWidget {
  final String assetCode;
  final String assetName;
  final String assetImage;
  final int statusSO;
  final String username;

  const DetailAssetDialog({
    Key? key,
    required this.assetCode,
    required this.assetName,
    required this.assetImage,
    required this.statusSO,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DetailAssetViewModel()..loadImage(assetImage),
      child: Consumer<DetailAssetViewModel>(
        builder: (context, viewModel, child) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 700, // Fixed width
              height: 400, // Fixed height
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          'Asset Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Gambar dan Detail
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gambar di sebelah kiri
                            GestureDetector(
                              onTap: () {
                                if (viewModel.imageBytes != null) {
                                  _showZoomableImageDialog(
                                    context,
                                    viewModel.imageBytes!,
                                  );
                                }
                              },
                              child: Container(
                                width: 300, // Fixed width for image
                                height: 300, // Fixed height for image
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: viewModel.isLoading
                                      ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                      : viewModel.errorMessage != null
                                      ? Center(
                                    child: Text(
                                      viewModel.errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                      : viewModel.imageBytes != null
                                      ? Image.memory(
                                    viewModel.imageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                      : const Center(
                                    child: Text(
                                      'No Image Available',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Detail di sebelah kanan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Asset Code', assetCode),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Asset Name', assetName),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                      'Status', statusSO.toString()),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Submitted by', username),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tombol X di sudut kanan atas
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Tutup dialog
                      },
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis, // Potong teks jika terlalu panjang
          ),
        ),
      ],
    );
  }

  void _showZoomableImageDialog(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // Membuat background dialog transparan
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}