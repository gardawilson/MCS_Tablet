import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/stock_opname_view_model.dart';
import 'stock_opname_input_screen.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/add_noso_dialog.dart';

class StockOpnameListScreen extends StatefulWidget {
  @override
  _StockOpnameListScreenState createState() => _StockOpnameListScreenState();
}

class _StockOpnameListScreenState extends State<StockOpnameListScreen> {
  List<String> selectedItems = []; // Menyimpan noSO item yang dipilih

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<StockOpnameViewModel>(context, listen: false).fetchStockOpname();
    });
  }


  void toggleSelection(String noSO) {
    setState(() {
      if (selectedItems.contains(noSO)) {
        selectedItems.remove(noSO); // Hapus dari daftar jika sudah dipilih
      } else {
        selectedItems.add(noSO); // Tambahkan ke daftar jika belum dipilih
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedItems.clear(); // Bersihkan semua seleksi
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedItems.isNotEmpty
          ? AppBar(
        title: Text('${selectedItems.length} Dipilih'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: clearSelection, // Reset semua seleksi
        ),
        actions: [
          if (selectedItems.length == 1) // Hanya tampilkan Edit jika satu item dipilih
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final noSO = selectedItems.first;
                final stockOpname = Provider.of<StockOpnameViewModel>(
                  context,
                  listen: false,
                ).stockOpnameList.firstWhere((item) => item.noSO == noSO);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockOpnameInputScreen(
                      noSO: stockOpname.noSO,
                      tgl: stockOpname.tgl,
                    ),
                  ),
                );
                clearSelection(); // Kembalikan ke mode normal setelah edit
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _confirmDelete();
            },
          ),
        ],
      )
          : AppBar(
        title: const Text('Stock Opname List'),
        backgroundColor: const Color(0xFF7a1b0c),
      ),
      body: Consumer<StockOpnameViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.stockOpnameList.isEmpty) {
            return const LoadingSkeleton();
          }

          if (viewModel.stockOpnameList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.errorMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.fetchStockOpname();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7a1b0c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.fetchStockOpname();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: viewModel.stockOpnameList.length,
              itemBuilder: (context, index) {
                final stockOpname = viewModel.stockOpnameList[index];
                final isSelected = selectedItems.contains(stockOpname.noSO); // Cek apakah item dipilih

                return GestureDetector(
                  onLongPress: () {
                    toggleSelection(stockOpname.noSO); // Aktifkan mode seleksi
                  },
                  onTap: () {
                    if (selectedItems.isNotEmpty) {
                      toggleSelection(stockOpname.noSO); // Tambahkan atau hapus dari seleksi
                    } else {
                      // Navigasi ke detail jika tidak dalam mode seleksi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockOpnameInputScreen(
                            noSO: stockOpname.noSO,
                            tgl: stockOpname.tgl,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isSelected ? Colors.grey[200] : Colors.white, // Ubah warna jika dipilih
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: NoSO and Tanggal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // NoSO
                              Text(
                                stockOpname.noSO,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a1a1a),
                                ),
                              ),
                              // Tanggal
                              Text(
                                stockOpname.tgl,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Divider
                          const Divider(color: Colors.grey, thickness: 0.5),

                          // Companies
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.business, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stockOpname.companies.join(', '),
                                    style: const TextStyle(fontSize: 14, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                          // Categories
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.category, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stockOpname.categories.join(', '),
                                    style: const TextStyle(fontSize: 14, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                          // Locations
                          if (stockOpname.locations.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stockOpname.locations.join(', '),
                                    style: const TextStyle(fontSize: 14, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
            ),
          );
        },
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? null
          : FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddNosoDialog(),
          );
        },
        backgroundColor: const Color(0xFF7a1b0c),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus item yang dipilih?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async { // Tambahkan async di sini
                // Ambil instance ViewModel
                final viewModel = Provider.of<StockOpnameViewModel>(
                  context,
                  listen: false,
                );

                // Ambil daftar nomor yang akan dihapus
                final deletedNumbers = viewModel.stockOpnameList
                    .where((item) => selectedItems.contains(item.noSO))
                    .map((item) => item.noSO)
                    .toList();

                // Hapus dari backend (API) dan local state
                bool allDeleted = true;
                for (final noSO in deletedNumbers) {
                  try {
                    await viewModel.deleteStockOpname(noSO); // Panggil fungsi delete di ViewModel
                  } catch (e) {
                    allDeleted = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus $noSO: ${e.toString()}')),
                    );
                  }
                }

                // Jika semua berhasil dihapus
                if (allDeleted) {
                  // Hapus dari local state (opsional, karena ViewModel sudah otomatis update)
                  viewModel.stockOpnameList.removeWhere(
                        (item) => selectedItems.contains(item.noSO),
                  );

                  // Bersihkan seleksi
                  clearSelection();

                  // Tampilkan notifikasi sukses
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil dihapus!')),
                  );
                }

                Navigator.pop(context); // Tutup dialog
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}