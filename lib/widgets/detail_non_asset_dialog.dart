import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/detail_asset_view_model.dart';
import '../view_models/non_asset_list_view_model.dart';
import '../widgets/add_non_asset_dialog.dart';
import 'dart:typed_data';


class DetailNonAssetDialog extends StatelessWidget {
  final int idNonAsset;
  final String noSO;
  final String nonAssetName;
  final String assetImage;
  final String nonAssetLocation;
  final String remark;
  final String username;

  const DetailNonAssetDialog({
    Key? key,
    required this.idNonAsset,
    required this.noSO,
    required this.nonAssetName,
    required this.assetImage,
    required this.nonAssetLocation,
    required this.remark,
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
                          'Non Asset Details',
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
                                  _buildDetailRow('Asset Name', nonAssetName.toUpperCase()),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Remark', remark.toUpperCase()),
                                  const SizedBox(height: 8),
                                  // _buildDetailRow('Submitted by', username),
                                  const SizedBox(height: 175),
                                  // Tombol Edit & Delete
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          //Reset Image Sebelumnya
                                          // Provider.of<NoAssetViewModel>(context, listen: false)
                                          //     .clearSelectedImage();

                                          showDialog(
                                            context: context,
                                            builder: (_) => AddNonAssetDialog(
                                              idNonAsset: idNonAsset,
                                              noSO: noSO,
                                              initialImageUrl: viewModel.imageUrl,
                                              initialLocation: nonAssetLocation,
                                              initialNonAssetName: nonAssetName,
                                              initialRemark: remark,
                                              isEdit: true,
                                              onSuccess: () {
                                                // ✅ Trigger refresh list dari ViewModel
                                                Provider.of<NoAssetViewModel>(context, listen: false)
                                                    .fetchNonAssetItems(noSO);

                                                // Jika ingin juga tutup DetailNonAssetDialog setelah update:
                                                Navigator.pop(context);
                                              },
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
                                      StatefulBuilder(
                                        builder: (context, setState) {
                                          bool isDeleting = false;

                                          return ElevatedButton.icon(
                                            onPressed: isDeleting
                                                ? null
                                                : () async {
                                              setState(() => isDeleting = true);
                                              final noAssetViewModel = Provider.of<NoAssetViewModel>(context, listen: false);

                                              try {
                                                await noAssetViewModel.deleteSelectedItems([idNonAsset]);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Icon(Icons.delete_forever, color: Colors.white),
                                                        SizedBox(width: 10),
                                                        Text('Asset Berhasil Dihapus!'),
                                                      ],
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    duration: Duration(seconds: 3),
                                                  ),
                                                );

                                                noAssetViewModel.fetchNonAssetItems(noSO); // Refresh list
                                                Navigator.pop(context); // Tutup dialog
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to delete item: $e')),
                                                );
                                              } finally {
                                                setState(() => isDeleting = false);
                                              }
                                            },
                                            icon: isDeleting
                                                ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                                : const Icon(Icons.delete, size: 18),
                                            label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        },
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