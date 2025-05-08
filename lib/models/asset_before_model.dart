class AssetBeforeModel {
  final String assetCode;
  final String assetName;

  AssetBeforeModel({
    required this.assetCode,
    required this.assetName,
  });

  factory AssetBeforeModel.fromJson(Map<String, dynamic> json) {
    return AssetBeforeModel(
      assetCode: json['AssetCode'] ?? 'Unknown',  // Beri nilai default jika null
      assetName: json['AssetName'] ?? 'Unknown',  // Beri nilai default jika null
    );
  }
}
