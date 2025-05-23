import 'package:flutter/material.dart';
import '../view_models/stock_opname_view_model.dart';
import '../view_models/master_data_view_model.dart';
import 'package:provider/provider.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:awesome_dialog/awesome_dialog.dart';




class AddNosoDialog extends StatefulWidget {
  @override
  _AddNosoDialogState createState() => _AddNosoDialogState();
}

class _AddNosoDialogState extends State<AddNosoDialog> {
  final TextEditingController tanggalTextController = TextEditingController();
  final Set<String> _selectedCompanies = {}; // Untuk menyimpan pilihan Company
  final Set<String> _selectedCategories = {}; // Untuk menyimpan pilihan Categories
  final Set<String> _selectedLocations = {}; // Untuk menyimpan pilihan Locations
  String? tanggalError; // Variabel untuk menyimpan pesan error
  bool _isBOM = false;


  @override
  void initState() {
    super.initState();
    // Panggil API untuk No SO dan Master Data hanya sekali
    Future.microtask(() {
      Provider.of<MasterDataViewModel>(context, listen: false).fetchMasterData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final masterViewModel = Provider.of<MasterDataViewModel>(context, listen: true);

    return AlertDialog(
      title: const Text("Header Stock Opname"),
      content: SizedBox(
        width: 600, // Ukuran tetap untuk lebar dialog
        child: Column(
          mainAxisSize: MainAxisSize.min, // Supaya dialog hanya sebesar kontennya
          children: [
            // Row untuk NoSO
            const SizedBox(height: 10), // Jarak antar elemen

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 100, // Lebar untuk label
                  child: Text(
                    "No SO",
                    style: TextStyle(fontSize: 16), // Gaya teks label
                  ),
                ),
                const SizedBox(
                  width: 10, // Spasi antar elemen
                  child: Text(
                    ":",
                    style: TextStyle(fontSize: 16), // Gaya teks label
                  ),
                ),
                Expanded(
                  child: Text(
                    "SO.XXXXXXXX",
                    style: const TextStyle(fontSize: 16), // Gaya teks NoSO
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10), // Jarak antar elemen

            // Row untuk TanggalSO
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 100, // Lebar untuk label
                  child: Text(
                    "Tanggal",
                    style: TextStyle(fontSize: 16), // Gaya teks label
                  ),
                ),
                const SizedBox(
                  width: 10, // Spasi antar elemen
                  child: Text(
                    ":",
                    style: TextStyle(fontSize: 16), // Gaya teks label
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: tanggalTextController,
                    readOnly: true, // Membuat TextField hanya bisa diklik, tidak bisa diketik
                    decoration: InputDecoration(
                      hintText: "Tanggal",
                      filled: true,
                      prefixIcon: Icon(Icons.calendar_today),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      errorText: tanggalError, // Tampilkan pesan error jika ada

                    ),
                    onTap: () async {
                      // Tampilkan dialog pemilihan tanggal
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(), // Tanggal default saat dialog muncul
                        firstDate: DateTime(2000), // Tanggal paling awal yang bisa dipilih
                        lastDate: DateTime(2100), // Tanggal paling akhir yang bisa dipilih
                      );

                      // Jika pengguna memilih tanggal, masukkan ke dalam controller
                      if (selectedDate != null) {
                        setState(() {
                          tanggalTextController.text =
                          "${selectedDate.toLocal()}".split(' ')[0]; // Format tanggal menjadi yyyy-MM-dd
                          tanggalError = null; // Hapus pesan error jika ada

                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10), // Jarak antar elemen

            // Row untuk Pilihan Company
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 100, // Lebar untuk label
                      child: Text(
                        "Company",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // Bagian untuk Chips
                masterViewModel.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : masterViewModel.errorMessage.isNotEmpty
                    ? Center(child: Text('❌ ${masterViewModel.errorMessage}'))
                    : Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: masterViewModel.companies.map((company) {
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
                        setState(() {
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
              ],
            ),

            const SizedBox(height: 10), // Jarak antara teks dan chip

            // Row untuk Pilihan Category
            Flexible(  // <-- Ganti Expanded dengan Flexible
              fit: FlexFit.loose,  // <-- Tambahkan ini untuk behavior yang lebih ringan
              child: masterViewModel.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : masterViewModel.errorMessage.isNotEmpty
                  ? Center(child: Text('❌ ${masterViewModel.errorMessage}'))
                  : Column(
                mainAxisSize: MainAxisSize.min,  // <-- Tetap penting
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Category",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),  // Spasi antara teks dan dropdown
                  MultiSelectDialogField(
                    items: masterViewModel.categories
                        .map((category) => MultiSelectItem(
                        category.categoryCode, category.categoryName))
                        .toList(),
                    title: const Text("Pilih Category"),
                    buttonText: _selectedCategories.isEmpty
                        ? const Text("Pilih Category")
                        : Text("${_selectedCategories.length} Category Selected"),
                    initialValue: _selectedCategories.toList(),
                    searchable: false,
                    listType: MultiSelectListType.CHIP,
                    onConfirm: (values) {
                      setState(() {
                        _selectedCategories.clear();
                        _selectedCategories.addAll(values.cast<String>());
                      });
                    },
                    chipDisplay: MultiSelectChipDisplay.none(),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.5),
                    ),
                    buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black),
                    selectedColor: Colors.green.shade100,
                    selectedItemsTextStyle: TextStyle(color: Colors.green),
                    cancelText: Text("Batal"),
                    confirmText: Text("Pilih"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Row untuk Pilihan Location
            Flexible(
              fit: FlexFit.loose, // Menggunakan loose fit untuk menghindari ekspansi berlebihan
              child: masterViewModel.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : masterViewModel.errorMessage.isNotEmpty
                  ? Center(child: Text('❌ ${masterViewModel.errorMessage}'))
                  : Column(
                mainAxisSize: MainAxisSize.min, // Penting untuk menghindari margin bawah
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Location",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8), // Spasi antara teks dan dropdown
                  MultiSelectDialogField(
                    items: masterViewModel.locations
                        .map((location) => MultiSelectItem(
                        location.locationCode, location.locationName))
                        .toList(),
                    title: const Text("Pilih Location"),
                    buttonText: _selectedLocations.isEmpty
                        ? const Text("Pilih Location")
                        : Text("${_selectedLocations.length} Location Selected"),
                    initialValue: _selectedLocations.toList(),
                    searchable: true,
                    listType: MultiSelectListType.CHIP,
                    onConfirm: (values) {
                      setState(() {
                        _selectedLocations.clear();
                        _selectedLocations.addAll(values.cast<String>());
                      });
                    },
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.5),
                    ),
                    buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.black),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    selectedColor: Colors.orange.shade100,
                    selectedItemsTextStyle: TextStyle(color: Colors.orange),
                    cancelText: Text("Batal"),
                    confirmText: Text("Pilih"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10), // Jarak antara teks dan chip

            Row(
              children: [
                Checkbox(
                  value: _isBOM,
                  onChanged: (bool? value) {
                    setState(() {
                      _isBOM = value ?? false;
                    });
                  },
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isBOM = !_isBOM;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text(
                      "BOM Only",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Tutup dialog tanpa menyimpan data
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7a1b0c),
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final tglSO = tanggalTextController.text; // Nilai dari TextField
            final isBOM = _isBOM;

            // Jika pengguna tidak memilih apa pun, gunakan semua data dari masterViewModel
            final selectedCompanies = _selectedCompanies.isEmpty
                ? masterViewModel.companies.map((company) => company.companyId).toList()
                : _selectedCompanies.toList();

            final selectedCategories = _selectedCategories.isEmpty
                ? masterViewModel.categories.map((category) => category.categoryCode).toList()
                : _selectedCategories.toList();

            final selectedLocations = _selectedLocations.isEmpty
                ? masterViewModel.locations.map((location) => location.locationCode).toList()
                : _selectedLocations.toList();

            // Tampilkan nilainya di console
            print("Tanggal Stock Opname: $tglSO");
            print("Selected Companies: $selectedCompanies");
            print("Selected Categories: $selectedCategories");
            print("Selected Locations: $selectedLocations");

            // Panggil ViewModel untuk melakukan POST
            final viewModel = Provider.of<StockOpnameViewModel>(context, listen: false);
            final success = await viewModel.submitStockOpname(
              tanggal: tglSO,
              idCompanies: selectedCompanies,
              idCategories: selectedCategories,
              idLocations: selectedLocations,
              isBOM: isBOM,
            );

            if (success) {
              Navigator.of(context).pop(); // Tutup dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Nomor SO Berhasil Dibuat!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              // Jika gagal
              setState(() {
                tanggalError = "Pilih Tanggal!"; // Set pesan error
              });
            }
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}