class AssetAfterModel {
  final String assetCode;
  final String username;
  final String assetName;

  AssetAfterModel({
    required this.assetCode,
    required this.username,
    required this.assetName,
  });

  factory AssetAfterModel.fromJson(Map<String, dynamic> json) {
    return AssetAfterModel(
      assetCode: json['AssetCode'] ?? 'Unknown',  // Beri nilai default jika null
      username: json['Username'] ?? 'No User',    // Beri nilai default jika null
      assetName: json['AssetName'] ?? 'Unknown',    // Beri nilai default jika null
    );
  }
}
