class NoAssetItem {
  final int id;
  final String noSO;
  final String image;
  final String nonAssetName;
  final String remark;

  NoAssetItem({
    required this.id,
    required this.noSO,
    required this.image,
    required this.nonAssetName,
    required this.remark,
  });

  factory NoAssetItem.fromJson(Map<String, dynamic> json) {
    return NoAssetItem(
      id: json['non_asset_id'],
      noSO: json['NoSO'],
      image: json['image'],
      nonAssetName: json['non_asset_name'],
      remark: json['remark'],
    );
  }
}
