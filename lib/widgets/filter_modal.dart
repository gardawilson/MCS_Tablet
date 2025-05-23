import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // kalau kamu pakai multi_select

import '../view_models/master_data_view_model.dart'; // sesuaikan import ViewModel kamu
import '../view_models/stock_opname_input_view_model.dart';

class FilterModalWidget extends StatefulWidget {
  final String noSO; // untuk passing noSO dari parent

  const FilterModalWidget({Key? key, required this.noSO}) : super(key: key);

  @override
  _FilterModalWidgetState createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget> {
  late MasterDataViewModel masterVM;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
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

          return SingleChildScrollView(
            child: Column(
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
                    final isSelected = vm.selectedCompanies.contains(company.companyId);
                    return ChoiceChip(
                      label: Text(company.companyName),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        // Update pilihan di ViewModel
                        vm.toggleCompany(company.companyId);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: vm.categories.map((category) {
                    final isSelected = vm.selectedCategories.contains(category.categoryCode);
                    return ChoiceChip(
                      label: Text(category.categoryName),
                      selected: isSelected,
                      selectedColor: Colors.green.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.green : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        vm.toggleCategory(category.categoryCode);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
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
                  initialValue: vm.selectedLocations.toList(),
                  searchable: true,
                  listType: MultiSelectListType.CHIP,
                  onConfirm: (values) {
                    vm.setSelectedLocations(values.toSet().cast<String>());
                  },
                  chipDisplay: MultiSelectChipDisplay(
                    scroll: true,
                    height: 50,
                    chipColor: Colors.orange.shade100,
                    textStyle: TextStyle(color: Colors.orange),
                  ),
                  selectedColor: Colors.orange.shade100,
                  selectedItemsTextStyle: TextStyle(color: Colors.orange),
                  cancelText: Text("Batal"),
                  confirmText: Text("Pilih"),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      final viewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);
                      viewModel.fetchAssetsAfter(
                        widget.noSO,
                        companyFilters: vm.selectedCompanies.toList(),
                        categoryFilters: vm.selectedCategories.toList(),
                        locationFilters: vm.selectedLocations.toList(),
                      );
                      viewModel.fetchAssetsBefore(
                        widget.noSO,
                        companyFilters: vm.selectedCompanies.toList(),
                        categoryFilters: vm.selectedCategories.toList(),
                        locationFilters: vm.selectedLocations.toList(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7a1b0c),
                      minimumSize: Size(double.infinity, 48),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Terapkan Filter',
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
          );
        },
      ),
    );
  }
}
