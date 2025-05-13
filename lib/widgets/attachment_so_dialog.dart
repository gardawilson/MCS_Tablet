import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/attachment_so_view_model.dart';
import '../view_models/master_data_view_model.dart';
import '../models/status_so_model.dart';

class AttachmentSODialog extends StatefulWidget {
  final String assetCode;
  final String noSO;

  const AttachmentSODialog({Key? key, required this.assetCode, required this.noSO}) : super(key: key);

  @override
  State<AttachmentSODialog> createState() => _AttachmentSODialogState();
}

class _AttachmentSODialogState extends State<AttachmentSODialog> {
  StatusSO? selectedStatus;
  late MasterDataViewModel masterVM;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      masterVM = Provider.of<MasterDataViewModel>(context, listen: false);
      masterVM.fetchStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AttachmentSOViewModel>(context);
    final masterData = Provider.of<MasterDataViewModel>(context);
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Attachment Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),

                    Text(
                      'Asset Code: ${widget.assetCode}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),

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
                                : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
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

                    masterData.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<StatusSO>(
                      value: selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: masterData.statuses.map((status) {
                        return DropdownMenuItem<StatusSO>(
                          value: status,
                          child: Text(status.status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validasi input
                          if (viewModel.selectedImage == null || selectedStatus == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an image and status.')),
                            );
                            return;
                          }

                          try {
                            // Simpan gambar ke SMB folder dan dapatkan nama file
                            final imageName = await viewModel.saveImageToSmbFolder(context);
                            if (imageName == null) throw Exception("Failed to save image to SMB folder.");

                            // Kirim data attachment ke API
                            await viewModel.sendAttachment(
                              noSO: widget.noSO,
                              assetCode: widget.assetCode,
                              status: selectedStatus!.id.toString(),
                              imageName: imageName,
                            );

                            // Tampilkan pesan sukses dan tutup dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Attachment submitted successfully!')),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            // Tangani error dan tampilkan pesan kesalahan
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7a1b0c),
                          minimumSize: Size(double.infinity, 48),  // Lebar penuh dan tinggi tombol
                          padding: EdgeInsets.symmetric(vertical: 14),  // Padding vertikal yang lebih besar
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),  // Sudut tombol yang lebih membulat
                          ),
                        ),
                        child: Text(
                          'Submit',  // Teks tombol
                          style: TextStyle(
                            fontSize: 16,  // Ukuran font
                            fontWeight: FontWeight.bold,  // Menambah ketebalan teks
                            color: Colors.white,  // Teks berwarna putih
                          ),
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
            color: Colors.black.withOpacity(0.5), // Latar belakang semi-transparan
            child: const Center(
              child: CircularProgressIndicator(), // Indikator loading
            ),
          ),
      ],
    );
  }
}