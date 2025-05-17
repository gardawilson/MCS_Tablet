import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/non_asset_list_view_model.dart';
import '../view_models/master_data_view_model.dart';
import '../models/location_model.dart';
import 'package:dropdown_search/dropdown_search.dart';


class AddNonAssetDialog extends StatefulWidget {
  final int idNonAsset;
  final String noSO;
  final String? initialImageUrl;
  final String? initialLocation;
  final String? initialNonAssetName;
  final String? initialRemark;
  final bool isEdit;
  final VoidCallback? onSuccess;

  const AddNonAssetDialog({
    Key? key,
    required this.idNonAsset,
    required this.noSO,
    this.initialImageUrl,
    this.initialLocation,
    this.initialNonAssetName,
    this.initialRemark,
    this.isEdit = false,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<AddNonAssetDialog> createState() => _AddNonAssetDialogState();
}

class _AddNonAssetDialogState extends State<AddNonAssetDialog> {
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _nonAssetNameController = TextEditingController();
  String? currentImageUrl;
  Location? selectedLocation;


  @override
  void initState() {
    super.initState();
    _remarkController.text = widget.initialRemark ?? '';
    _nonAssetNameController.text = widget.initialNonAssetName ?? '';
    currentImageUrl = widget.initialImageUrl;

    // Ambil data lokasi dulu baru set selectedLocation
    Future.microtask(() async {
      final masterData = Provider.of<MasterDataViewModel>(context, listen: false);
      if (masterData.locations.isEmpty) {
        await masterData.fetchMasterData();
      }

      if (widget.initialLocation != null) {
        setState(() {
          selectedLocation = masterData.locations.firstWhere(
                (loc) => loc.locationCode == widget.initialLocation,
            orElse: () => masterData.locations.first, // default jika tidak ketemu
          );
        });
      }
    });
  }


  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NoAssetViewModel>(context);
    final masterData = Provider.of<MasterDataViewModel>(context); // Tambahkan ini
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: screenWidth * 0.5,
            height: screenHeight * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Attachment Details',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: viewModel.pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: viewModel.selectedImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                viewModel.selectedImage!,
                                fit: BoxFit.contain,
                              ),
                            )
                                : currentImageUrl != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                currentImageUrl!,
                                fit: BoxFit.contain,
                              ),
                            )
                                : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to capture image.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<Location>(
                      value: selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Select Location',
                        border: OutlineInputBorder(),
                      ),
                      items: masterData.locations.map((location) {
                        return DropdownMenuItem<Location>(
                          value: location,
                          child: Text(location.locationName), // pastikan field `name` tersedia di model
                        );
                      }).toList(),
                      onChanged: (Location? newValue) {
                        setState(() {
                          selectedLocation = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _nonAssetNameController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Name',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 1,
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        labelText: 'Remark',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                          onPressed: () async {
                            try {
                              // Validasi gambar
                              if (viewModel.selectedImage == null && currentImageUrl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select or capture an image.')),
                                );
                                return;
                              }

                              if (selectedLocation == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a location.')),
                                );
                                return;
                              }

                              // Validasi remark
                              if (_nonAssetNameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill the Asset Name.')),
                                );
                                return;
                              }

                              // Validasi remark
                              if (_remarkController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill the remark.')),
                                );
                                return;
                              }

                              String imageName;

                              if (widget.isEdit) {
                                // ======== MODE EDIT =========
                                if (viewModel.isImageChanged) {
                                  imageName = await viewModel.replaceImage(oldImageName: currentImageUrl!.split('/').last, noSO: widget.noSO) ??
                                      (throw Exception('Failed to upload image.'));
                                  viewModel.isImageChanged = false;

                                } else {
                                  //Tidak perlu lakukan upload image
                                  imageName = currentImageUrl!.split('/').last;

                                }

                                // Di sini kamu bisa panggil update logic (misalnya updateNotAsset)
                                final success = await viewModel.updateNonAsset(
                                  idNonAsset: widget.idNonAsset,
                                  image: imageName,
                                  locationCode: selectedLocation!.locationCode,
                                  nonAssetName: _nonAssetNameController.text.trim(),
                                  remark: _remarkController.text.trim(),
                                );

                                if (success) {
                                  viewModel.clearSelectedImage();
                                  widget.onSuccess?.call();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 10),
                                          Text('Data berhasil diperbarui!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                // ======== MODE TAMBAH BARU =========
                                imageName = await viewModel.uploadImage(widget.noSO) ??
                                    (throw Exception('Failed to upload image.'));

                                final success = await viewModel.addNonAsset(
                                  noSO: widget.noSO,
                                  imageName: imageName,
                                  locationCode: selectedLocation!.locationCode,
                                  remark: _remarkController.text.trim(),
                                  nonAssetName: _nonAssetNameController.text.trim(),
                                );

                                if (success) {
                                  viewModel.clearSelectedImage();

                                  _remarkController.clear();

                                  widget.onSuccess?.call();
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 10),
                                          Text('Data Berhasil Disimpan!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7a1b0c),
                          minimumSize: const Size(double.infinity, 48),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (viewModel.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
