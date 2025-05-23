import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../view_models/stock_opname_input_view_model.dart';
import '../view_models/master_data_view_model.dart';
import '../view_models/attachment_so_view_model.dart';
import '../view_models/laporan_so_pdf_view_model.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/filter_modal.dart';
import '../widgets/attachment_so_dialog.dart';
import '../widgets/detail_asset_dialog.dart';
import '../views/barcode_qr_scan_screen.dart';
import '../views/non_asset_list_screen.dart';
import '../models/company_model.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';


class StockOpnameInputScreen extends StatefulWidget {
  final String noSO;
  final String tgl;
  final List<String> company;

  const StockOpnameInputScreen({Key? key, required this.noSO, required this.tgl, required this.company}) : super(key: key);

  @override
  _StockOpnameInputScreenState createState() => _StockOpnameInputScreenState();
}

class _StockOpnameInputScreenState extends State<StockOpnameInputScreen> {
  Set<String> _selectedCompanies = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedLocations = {};

  final ScrollController _scrollControllerBefore = ScrollController();
  final ScrollController _scrollControllerAfter = ScrollController();

  late MasterDataViewModel masterDataVM;


  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);
    masterDataVM = Provider.of<MasterDataViewModel>(context, listen: false);

    // Memanggil kedua fungsi secara paralel menggunakan Future.wait
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        // Memanggil fetchAssetsDataBefore untuk endpoint kedua
        viewModel.fetchAssetsBefore(widget.noSO),

        // Memanggil fetchAssets untuk endpoint pertama
        viewModel.fetchAssetsAfter(widget.noSO),

      ]).then((_) {
        // Setelah kedua API selesai dipanggil, lakukan setState untuk memperbarui UI
        setState(() {});
      }).catchError((error) {
        // Tangani error jika terjadi
        print('Error while fetching data: $error');
      });
    });
  }


  @override
  void dispose() {
    _scrollControllerBefore.dispose();
    _scrollControllerAfter.dispose();

    masterDataVM.clearFilters();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.tgl} ( ${widget.noSO} )',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7a1b0c),
        foregroundColor: Colors.white,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.filter_list, color: Colors.white),
        //     onPressed: () => _showFilterModal(context), // Memanggil modal saat tombol ditekan
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 1,  // Menambahkan efek bayangan
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Filter Button
                  ElevatedButton.icon(
                    onPressed: () => _showFilterModal(context, widget.noSO), // Memanggil modal saat tombol ditekan
                    icon: Icon(Icons.filter_list, color: Colors.black, size: 24),
                    label: Text(
                      'Filters',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,  // Membuat tombol transparan
                      elevation: 0,  // Tanpa bayangan
                      minimumSize: Size(100, 40),  // Ukuran minimum tombol agar tidak terlalu kecil
                    ),
                  ),
                  SizedBox(width: 16),
                  _buildCountText(),  // Menampilkan count di sebelah kanan
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // ListView sebelah kiri
                Expanded(
                  child: Consumer<StockOpnameInputViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.assetListBefore.isEmpty) {
                        if (viewModel.errorMessageBefore.contains("404")) {
                          return const Center(
                            child: Text(
                              'Tidak ada data ditemukan',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }

                        return Center(
                          child: Text(
                            viewModel.errorMessageBefore,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '📋 Daftar Asset Before (${viewModel.totalAssetsBefore})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollControllerBefore,
                              itemCount: viewModel.assetListBefore.length + (viewModel.hasMoreBefore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == viewModel.assetListBefore.length) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    viewModel.loadMoreAssetsBefore(
                                      widget.noSO,
                                      companyFilters: _selectedCompanies.toList(),
                                      categoryFilters: _selectedCategories.toList(),
                                      locationFilters: _selectedLocations.toList(),
                                    );
                                  });

                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final asset = viewModel.assetListBefore[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      asset.assetName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(asset.assetCode),
                                    leading: const Icon(Icons.inventory, color: Colors.blue),
                                    trailing: asset.hasNotBeenPrinted == 1
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const SizedBox(),
                                    onTap: () {
                                      if (asset.hasNotBeenPrinted == 0) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => MultiProvider(
                                            providers: [
                                              ChangeNotifierProvider(create: (_) => AttachmentSOViewModel())
                                            ],
                                            child: AttachmentSODialog(
                                              assetCode: asset.assetCode,
                                              noSO: widget.noSO,
                                            ),
                                          ),
                                        );
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) => DetailAssetDialog(
                                            assetCode: asset.assetCode,
                                            assetName: asset.assetName,
                                            assetImage: asset.assetImage,
                                            statusSO: asset.statusSO,
                                            username: asset.username,
                                            noSO: widget.noSO,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Garis pemisah vertikal
                const VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: Colors.grey,
                ),

                // ListView sebelah kanan
                Expanded(
                  child: Consumer<StockOpnameInputViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.assetListAfter.isEmpty) {
                        if (viewModel.errorMessageAfter.contains("404")) {
                          return const Center(
                            child: Text(
                              'Tidak ada data ditemukan',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }

                        return Center(
                          child: Text(
                            viewModel.errorMessageAfter,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '📋 Daftar Asset After (${viewModel.totalAssetsAfter})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollControllerAfter,
                              itemCount: viewModel.assetListAfter.length + (viewModel.hasMoreAfter ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Jika ini index terakhir dan ada data lagi untuk di-load (loading indicator)
                                if (index == viewModel.assetListAfter.length &&
                                    viewModel.assetListAfter.isNotEmpty &&
                                    !viewModel.isRealtimeUpdateInProgress) {

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    viewModel.loadMoreAssetsAfter(
                                      widget.noSO,
                                      companyFilters: _selectedCompanies.toList(),
                                      categoryFilters: _selectedCategories.toList(),
                                      locationFilters: _selectedLocations.toList(),
                                    );
                                  });

                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                // **Pastikan index masih valid sebelum akses list**
                                if (index < viewModel.assetListAfter.length) {
                                  final asset = viewModel.assetListAfter[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        asset.assetName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(asset.assetCode),
                                          Text('Scanned By: ${asset.username}'),
                                        ],
                                      ),
                                      leading: const Icon(Icons.inventory, color: Colors.blue),
                                    ),
                                  );
                                }

                                // Fallback jika terjadi kasus tak terduga (misal index di luar batas)
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),



              ],
            ),
          ),
        ],
      ),

      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFF7a1b0c),
        foregroundColor: Colors.white,
        visible: true,
        curve: Curves.linear,
        spaceBetweenChildren: 16,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Scan QR',
            onTap: () {
              _showScanBarQRCode(context);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit_note),
            label: 'Input Manual',
            onTap: () {
              _showNoAssetList(context);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.summarize_outlined),
            label: 'Laporan',
            onTap: () {
              _showLaporanSOPdf(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context, String noSO) {
    final masterVM = Provider.of<MasterDataViewModel>(context, listen: false);

    // Pastikan data sudah di-fetch dulu, baru tampilkan modal
    if (masterVM.companies.isEmpty) {
      masterVM.fetchMasterData().then((_) {
        // Setelah data siap, tampilkan modal
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => FilterModalWidget(noSO: noSO),
        );
      });
    } else {
      // Data sudah ada, langsung tampilkan modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => FilterModalWidget(noSO: noSO),
      );
    }
  }


  Widget _buildCountText() {
    // Asumsi count didapatkan dari jumlah item yang ada di blokList
    final countAfter = Provider.of<StockOpnameInputViewModel>(context).totalAssetsAfter;
    final countBefore = Provider.of<StockOpnameInputViewModel>(context).totalAssetsBefore;
    int count = countAfter + countBefore;
    return Text(
      '$count Assets', // Menampilkan jumlah item
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }


  void _showScanBarQRCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeQrScanScreen(
            noSO: widget.noSO
        ),
      ),
    );
  }

  void _showNoAssetList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemNoAssetCode(
            noSO: widget.noSO
        ),
      ),
    );
  }

  void _showLaporanSOPdf(BuildContext context) async {
    final viewModel = context.read<ReportViewModel>();

    // Tampilkan loading dialog sebelum memulai proses
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa menutup dialog dengan tap di luar
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await viewModel.downloadAndOpenPdf(
      widget.noSO,
      widget.tgl,
      widget.company.join(', '),
    );

    // Tutup loading dialog setelah selesai (baik sukses maupun error)
    Navigator.of(context).pop();

    // Jika ada error, tampilkan snackbar
    if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.error!)),
      );
    }
  }

}
