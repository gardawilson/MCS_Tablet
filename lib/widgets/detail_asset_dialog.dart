import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/detail_asset_view_model.dart';
import '../view_models/attachment_so_view_model.dart';
import '../widgets/attachment_so_dialog.dart';
import '../view_models/stock_opname_input_view_model.dart';
import 'dart:typed_data';


class DetailAssetDialog extends StatelessWidget {
  final String assetCode;
  final String assetName;
  final String assetImage;
  final String statusSO;
  final String username;
  final String noSO;

  const DetailAssetDialog({
    Key? key,
    required this.assetCode,
    required this.assetName,
    required this.assetImage,
    required this.statusSO,
    required this.username,
    required this.noSO,
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
              height: 385, // Fixed height
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
                                if (viewModel.imageUrl != null) {
                                  _showZoomableImageDialog(context, viewModel.imageUrl!);
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
                                        : Image.network(
                                      viewModel.imageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Error loading image: $error');
                                        return const Center(
                                          child: Text(
                                            'Failed to load image',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        );
                                      },
                                    )
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
                                  _buildDetailRow('Status', statusSO.toString()),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Submitted by', username),
                                  const SizedBox(height: 140),
                                  // Tombol Edit & Delete
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);

                                          showDialog(
                                            context: context,
                                            builder: (_) => ChangeNotifierProvider(
                                              create: (_) => AttachmentSOViewModel(),
                                              child: AttachmentSODialog(
                                                assetCode: assetCode,
                                                noSO: noSO,
                                                initialImageUrl: viewModel.imageUrl,
                                                initialStatus: statusSO,
                                                isEdit: true,
                                              ),
                                            ),
                                          );

                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),

                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final attachmentViewModel = Provider.of<AttachmentSOViewModel>(context, listen: false);
                                          final stockOpnameViewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);


                                            await attachmentViewModel.sendAttachment(
                                              noSO: noSO,
                                              assetCode: assetCode,
                                              isUpdateValid: false,
                                              status: "",
                                              statusName: "",
                                              imageName: assetImage,
                                              stockOpnameViewModel: stockOpnameViewModel,
                                            );

                                            Navigator.pop(context); // Menutup dialog setelah selesai

                                        },
                                        icon: const Icon(Icons.delete, size: 18),
                                        label: const Text('Delete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),

                                    ],
                                  ),
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
            fontWeight: FontWeight.w700,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis, // Potong teks jika terlalu panjang
          ),
        ),
      ],
    );
  }

  void _showZoomableImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

}