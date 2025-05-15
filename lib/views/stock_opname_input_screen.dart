import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../view_models/stock_opname_input_view_model.dart';
import '../view_models/master_data_view_model.dart';
import '../view_models/attachment_so_view_model.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/attachment_so_dialog.dart';
import '../widgets/detail_asset_dialog.dart';
import '../views/barcode_qr_scan_screen.dart';
import '../views/not_asset_list_screen.dart';
import '../models/company_model.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';



class StockOpnameInputScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameInputScreen({Key? key, required this.noSO, required this.tgl}) : super(key: key);

  @override
  _StockOpnameInputScreenState createState() => _StockOpnameInputScreenState();
}

class _StockOpnameInputScreenState extends State<StockOpnameInputScreen> {
  Set<String> _selectedCompanies = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedLocations = {};

  final ScrollController _scrollControllerBefore = ScrollController();
  final ScrollController _scrollControllerAfter = ScrollController();

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);

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
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF7a1b0c),
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
                    onPressed: () => _showFilterModal(context), // Memanggil modal saat tombol ditekan
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

                      return ListView.builder(
                        controller: _scrollControllerBefore,
                        itemCount: viewModel.assetListBefore.length + (viewModel.hasMoreBefore ? 2 : 1),
                        itemBuilder: (context, index) {
                          final count = Provider.of<StockOpnameInputViewModel>(context).totalAssetsBefore;
                          if (index == 0) {
                            return Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '📋 Daftar Asset Kiri ($count)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            );
                          }

                          if (index == viewModel.assetListBefore.length + 1) {
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

                          final asset = viewModel.assetListBefore[index - 1];
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
                                        ChangeNotifierProvider(create: (_) => AttachmentSOViewModel()),
                                        ChangeNotifierProvider(create: (_) => MasterDataViewModel()),
                                      ],
                                      child: AttachmentSODialog(
                                        assetCode: asset.assetCode,
                                        noSO: widget.noSO, // Kirim assetCode dan noSO ke dialog
                                      ),
                                    ),
                                  );
                                } else {
                                  // Tampilkan dialog khusus jika hasNotBeenPrinted != 1
                                  showDialog(
                                    context: context,
                                    builder: (context) => DetailAssetDialog(
                                      assetCode: asset.assetCode,
                                      assetName: asset.assetName,
                                      assetImage: asset.assetImage,
                                      statusSO: asset.statusSO,
                                      username: asset.username,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
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

                      return ListView.builder(
                        controller: _scrollControllerAfter,
                        itemCount: viewModel.assetListAfter.length + (viewModel.hasMoreAfter ? 2 : 1),
                        itemBuilder: (context, index) {
                          final count = Provider.of<StockOpnameInputViewModel>(context).totalAssetsAfter;
                          if (index == 0) {
                            return Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '📋 Daftar Asset Kanan ($count)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            );
                          }

                          if (index == viewModel.assetListAfter.length + 1) {
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

                          final asset = viewModel.assetListAfter[index - 1];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(
                                asset.assetName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Agar teks rata kiri
                                children: [
                                  Text(asset.assetCode),
                                  Text('Scanned By: ${asset.username}'),
                                ],
                              ),
                              leading: const Icon(Icons.inventory, color: Colors.blue),
                            ),
                          );
                        },
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
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    final masterViewModel = Provider.of<MasterDataViewModel>(context, listen: false);
    masterViewModel.fetchMasterData(); // Ganti dari fetchCompanies()

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<MasterDataViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (vm.errorMessage.isNotEmpty) {
                    return Center(child: Text('❌ ${vm.errorMessage}'));
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: vm.companies.map((company) {
                          final isSelected = _selectedCompanies.contains(company.companyId);
                          return ChoiceChip(
                            label: Text(company.companyName),
                            selected: isSelected,
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.blue : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedCompanies.add(company.companyId);
                                } else {
                                  _selectedCompanies.remove(company.companyId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: vm.categories.map((category) {
                          final isSelected = _selectedCategories.contains(category.categoryCode);
                          return ChoiceChip(
                            label: Text(category.categoryName),
                            selected: isSelected,
                            selectedColor: Colors.green.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.green : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedCategories.add(category.categoryCode);
                                } else {
                                  _selectedCategories.remove(category.categoryCode);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      // Location Section - Scrollable & Responsive
                      Text(
                        'Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      MultiSelectDialogField(
                        items: vm.locations
                            .map((loc) => MultiSelectItem(loc.locationCode, loc.locationName))
                            .toList(),
                        title: Text("Pilih Lokasi"),
                        buttonText: Text("Klik untuk pilih lokasi"),
                        initialValue: _selectedLocations.toList(),
                        searchable: true,
                        listType: MultiSelectListType.CHIP,
                        onConfirm: (values) {
                          setModalState(() {
                            _selectedLocations = values.toSet().cast<String>();
                          });
                        },
                        chipDisplay: MultiSelectChipDisplay(
                          scroll: true, // Aktifkan scroll
                          height: 50, // Batasi tinggi untuk area scroll
                          chipColor: Colors.orange.shade100, // Warna latar belakang chip yang tidak dipilih
                          textStyle: TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                        selectedColor: Colors.orange.shade100,
                        selectedItemsTextStyle: TextStyle(
                          color: Colors.orange,
                        ),
                        cancelText: Text("Batal"), // Mengubah teks tombol Cancel
                        confirmText: Text("Pilih"), // Mengubah teks tombol Confirm (OK)
                      ),


                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            print("📦 Company: ${_selectedCompanies.join(', ')}");
                            print("📂 Category: ${_selectedCategories.join(', ')}");
                            print("📂 Location: ${_selectedLocations.join(', ')}");

                            final viewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);
                            viewModel.fetchAssetsAfter(
                              widget.noSO,
                              companyFilters: _selectedCompanies.toList(),
                              categoryFilters: _selectedCategories.toList(),
                              locationFilters: _selectedLocations.toList(),
                            );
                            viewModel.fetchAssetsBefore(
                              widget.noSO,
                              companyFilters: _selectedCompanies.toList(),
                              categoryFilters: _selectedCategories.toList(),
                              locationFilters: _selectedLocations.toList(),
                            );
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
                            'Terapkan Filter',  // Teks tombol
                            style: TextStyle(
                              fontSize: 16,  // Ukuran font
                              fontWeight: FontWeight.bold,  // Menambah ketebalan teks
                              color: Colors.white,  // Teks berwarna putih
                            ),
                          ),

                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
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


}
