import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/non_asset_list_view_model.dart';
import '../view_models/detail_asset_view_model.dart';
import '../widgets/add_non_asset_dialog.dart';
import '../models/not_asset_model.dart';
import '../widgets/detail_non_asset_dialog.dart';

class ItemNoAssetCode extends StatefulWidget {
  final String noSO;

  const ItemNoAssetCode({super.key, required this.noSO});

  @override
  State<ItemNoAssetCode> createState() => _ItemNoAssetCodeState();
}

class _ItemNoAssetCodeState extends State<ItemNoAssetCode> {
  late NoAssetViewModel viewModel;
  bool isSelectionMode = false;
  final Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    viewModel = Provider.of<NoAssetViewModel>(context, listen: false);
    viewModel.fetchNoAssetItems(widget.noSO);
  }

  void toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
        if (selectedIds.isEmpty) isSelectionMode = false;
      } else {
        selectedIds.add(id);
        isSelectionMode = true;
      }
    });
  }

  void clearSelection() {
    setState(() {
      isSelectionMode = false;
      selectedIds.clear();
    });
  }

  void deleteSelectedItems() async {
    try {
      await viewModel.deleteSelectedItems(selectedIds.toList());
      await viewModel.fetchNoAssetItems(widget.noSO);
      clearSelection();

      if (context.mounted) {
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

      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: clearSelection,
        )
            : BackButton(),
        title: isSelectionMode
            ? Text('${selectedIds.length} dipilih')
            : Text('Non Asset  (${widget.noSO})'),
        backgroundColor: isSelectionMode
            ? Colors.white  // warna saat seleksi
            : const Color(0xFF7a1b0c), // warna default
        actions: isSelectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteSelectedItems,
          ),
        ]
            : null,
      ),


      body: _buildBody(),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: const Color(0xFF7a1b0c),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Data No Asset',
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<NoAssetViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF7a1b0c)),
            ),
          );
        }

        if (vm.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Tidak ada Data",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                TextButton(
                  onPressed: () => vm.fetchNoAssetItems(widget.noSO),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vm.fetchNoAssetItems(widget.noSO),
          color: const Color(0xFF7a1b0c),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: vm.items.length,
            itemBuilder: (context, index) {
              final item = vm.items[index];
              final isSelected = selectedIds.contains(item.id);

              return GestureDetector(
                onLongPress: () => toggleSelection(item.id),
                onTap: isSelectionMode
                    ? () => toggleSelection(item.id)
                    : () {
                  showDialog(
                    context: context,
                    builder: (_) => DetailNonAssetDialog(
                      idNonAsset: item.id,
                      noSO: widget.noSO,
                      nonAssetName: item.nonAssetName,
                      assetImage: item.image,
                      remark:  item.remark,
                      username: 'N/A',
                    ),
                  );
                },

                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: isSelected ? Colors.grey.shade400 : null,
                  elevation: 2,
                  child: ListTile(
                    leading: Text(
                      '${index + 1}', // Menampilkan nomor urut berdasarkan index
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    title: Text(item.remark),
                  ),
                ),

              );
            },
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AddNonAssetDialog(
        idNonAsset: 0,
        noSO: widget.noSO,
        onSuccess: () async {
          await viewModel.fetchNoAssetItems(widget.noSO);
          viewModel.isImageChanged = false;

          // if (context.mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(
          //       content: Text('Data berhasil ditambahkan!'),
          //       duration: Duration(seconds: 1),
          //     ),
          //   );
          // }
        },
      ),
    );
  }
}
