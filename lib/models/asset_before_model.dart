class AssetBeforeModel {
  final String assetCode;
  final String assetName;
  final int hasNotBeenPrinted;
  final String assetImage;
  final int statusSO;
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
      assetCode: json['AssetCode'] ?? 'Unknown',  // Beri nilai default jika null
      assetName: json['AssetName'] ?? 'Unknown',  // Beri nilai default jika null
      hasNotBeenPrinted: json['HasNotBeenPrinted'],
      assetImage: json['Image'] ?? 'Unknown',
      statusSO: json['IdStatus'] ?? -1,
      username: json['id_user'] ?? 'Unknown',

    );
  }
}
