class AssetBeforeModel {
  final String assetCode;
  final String assetName;
  final int hasNotBeenPrinted;
  final String assetImage;
  final String statusSO;
  final String username;

  AssetBeforeModel({
    required this.assetCode,
    required this.assetName,
    required this.hasNotBeenPrinted,
    required this.assetImage,
    required this.statusSO,
    required this.username,
  });

  factory AssetBeforeModel.fromJson(Map<String, dynamic> json) {
    return AssetBeforeModel(
      assetCode: json['AssetCode'] ?? 'Unknown',
      assetName: json['AssetName'] ?? 'Unknown',
      hasNotBeenPrinted: json['HasNotBeenPrinted'],
      assetImage: json['Image'] ?? 'Unknown',
      statusSO: json['status'] ?? 'Unknown',
      username: (json['username'] ?? 'Unknown').toString().toUpperCase(),
    );
  }

}
