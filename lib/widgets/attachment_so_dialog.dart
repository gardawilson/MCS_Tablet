import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/attachment_so_view_model.dart';
import '../view_models/status_so_view_model.dart';
import '../view_models/stock_opname_input_view_model.dart';
import '../models/status_so_model.dart';

class AttachmentSODialog extends StatefulWidget {
  final String assetCode;
  final String noSO;
  final String? initialImageUrl;
  final String? initialStatus; // String status
  final bool isEdit;


  const AttachmentSODialog({
    Key? key,
    required this.assetCode,
    required this.noSO,
    this.initialImageUrl,
    this.initialStatus,
    this.isEdit = false,  // default false (submit baru)
  }) : super(key: key);

  @override
  State<AttachmentSODialog> createState() => _AttachmentSODialogState();
}

class _AttachmentSODialogState extends State<AttachmentSODialog> {
  String? selectedStatus;
  String? currentImageUrl;
  late StatusSOViewModel statusVM;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    currentImageUrl = widget.initialImageUrl;

    Future.microtask(() {
      statusVM = Provider.of<StatusSOViewModel>(context, listen: false);
      statusVM.fetchStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AttachmentSOViewModel>(context);
    final masterData = Provider.of<StatusSOViewModel>(context);
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
                        )
                      ],
                    ),
                    Text(
                      'Asset Code: ${widget.assetCode}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                        : DropdownButtonFormField<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: masterData.statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status.status,
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
                        onPressed: viewModel.isLoading
                            ? null // 🔒 Disable tombol saat loading
                            : () async {
                          if (viewModel.selectedImage == null && currentImageUrl == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select or capture an image.')),
                            );
                            return;
                          }
                          if (selectedStatus == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a status.')),
                            );
                            return;
                          }

                          try {
                            viewModel.setLoading(true); // Aktifkan loading state

                            String? imageName;

                            if (widget.isEdit) {
                              if (!viewModel.isImageChanged) {
                                imageName = widget.initialImageUrl!.split('/').last;
                              } else {
                                imageName = await viewModel.replaceImage(oldImageName: widget.initialImageUrl!.split('/').last);
                                if (imageName == null) throw Exception("Failed to upload image.");
                              }
                              viewModel.isImageChanged = false;
                            } else {
                              if (viewModel.selectedImage == null) {
                                throw Exception("Please select or capture an image.");
                              }
                              imageName = await viewModel.uploadImage();
                              if (imageName == null) throw Exception("Failed to upload image.");
                            }

                            final stockOpnameViewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);
                            final matchedStatus = masterData.statuses.firstWhere(
                                  (s) => s.status == selectedStatus,
                              orElse: () => StatusSO(id: 0, status: selectedStatus!),
                            );

                            await viewModel.sendAttachment(
                              noSO: widget.noSO,
                              assetCode: widget.assetCode,
                              status: matchedStatus.id.toString(),
                              statusName: matchedStatus.status,
                              isUpdateValid: true,
                              imageName: imageName,
                              stockOpnameViewModel: stockOpnameViewModel,
                            );

                            Navigator.pop(context); // Tutup dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text('Upload attachment berhasil!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            viewModel.setLoading(false); // Nonaktifkan loading state
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
                        child: viewModel.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
        // if (viewModel.isLoading)
        //   Container(
        //     color: Colors.black.withOpacity(0.5),
        //     child: const Center(
        //       child: CircularProgressIndicator(),
        //     ),
        //   ),
      ],
    );
  }
}
