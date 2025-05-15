import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/not_asset_list_view_model.dart';

class AddNoAssetDialog extends StatefulWidget {
  final String noSO;
  final VoidCallback? onSuccess;

  const AddNoAssetDialog({
    Key? key,
    required this.noSO,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<AddNoAssetDialog> createState() => _AddNoAssetDialogState();
}

class _AddNoAssetDialogState extends State<AddNoAssetDialog> {
  final TextEditingController _remarkController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NoAssetViewModel>(context);
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: screenSize.width * 0.5,
            height: screenSize.height * 0.8,
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildImagePicker(viewModel),
                    const SizedBox(height: 16),
                    _buildRemarkField(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(viewModel),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isSubmitting || viewModel.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker(NoAssetViewModel viewModel) {
    return GestureDetector(
      onTap: _isSubmitting ? null : viewModel.pickImage,
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
                    color: _isSubmitting ? Colors.grey[300] : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to capture image',
                    style: TextStyle(
                      color: _isSubmitting ? Colors.grey[300] : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkField() {
    return TextField(
      controller: _remarkController,
      enabled: !_isSubmitting,
      decoration: const InputDecoration(
        labelText: 'Remark',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildSubmitButton(NoAssetViewModel viewModel) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _handleSubmit(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7a1b0c),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Submit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(NoAssetViewModel viewModel) async {
    if (viewModel.selectedImage == null || _remarkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih gambar dan isi remark')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imageName = await viewModel.uploadImage();
      if (imageName == null) throw Exception("Gagal upload gambar");

      final success = await viewModel.addNotAsset(
        noSO: widget.noSO,
        imageName: imageName,
        remark: _remarkController.text,
      );

      if (success && mounted) {
        // 1. Clear form state
        _remarkController.clear();
        viewModel.clearSelectedImage();

        // 2. Tutup dialog
        Navigator.pop(context);

        // 3. Beri callback untuk refresh
        widget.onSuccess?.call();

        // 4. Tampilkan notifikasi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disimpan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}