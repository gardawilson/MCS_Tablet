import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/company_model.dart';
import '../models/category_model.dart';
import '../models/location_model.dart';
import '../models/status_so_model.dart';
import '../constants/api_constants.dart';

class MasterDataViewModel extends ChangeNotifier {
  List<Company> companies = [];
  List<Category> categories = [];
  List<Location> locations = [];
  bool isLoading = false;
  String errorMessage = '';
  List<StatusSO> statuses = [];

  // State pilihan filter
  Set<String> selectedCompanies = {};
  Set<String> selectedCategories = {};
  Set<String> selectedLocations = {};

  Future<void> fetchMasterData() async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(ApiConstants.masterCompany),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final List<dynamic> companiesJson = jsonData['companies'];
        companies = companiesJson.map((e) => Company.fromJson(e)).toList();

        final List<dynamic> categoriesJson = jsonData['categories'];
        categories = categoriesJson.map((e) => Category.fromJson(e)).toList();

        final List<dynamic> locationsJson = jsonData['locations'];
        locations = locationsJson.map((e) => Location.fromJson(e)).toList();

        errorMessage = '';
      } else {
        errorMessage = 'Failed to load data (${response.statusCode})';
      }
    } catch (e) {
      errorMessage = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Methods untuk update pilihan filter
  void toggleCompany(String companyId) {
    if (selectedCompanies.contains(companyId)) {
      selectedCompanies.remove(companyId);
    } else {
      selectedCompanies.add(companyId);
    }
    notifyListeners();
  }

  void toggleCategory(String categoryCode) {
    if (selectedCategories.contains(categoryCode)) {
      selectedCategories.remove(categoryCode);
    } else {
      selectedCategories.add(categoryCode);
    }
    notifyListeners();
  }

  void setSelectedLocations(Set<String> locations) {
    selectedLocations = locations;
    notifyListeners();
  }

  void clearFilters() {
    selectedCompanies.clear();
    selectedCategories.clear();
    selectedLocations.clear();
  }
}
