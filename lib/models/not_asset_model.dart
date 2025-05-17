class NonAssetItem {
  final int id;
  final String noSO;
  final String image;
  final String locationCode;
  final String nonAssetName;
  final String remark;

  NonAssetItem({
    required this.id,
    required this.noSO,
    required this.image,
    required this.locationCode,
    required this.nonAssetName,
    required this.remark,
  });

  factory NonAssetItem.fromJson(Map<String, dynamic> json) {
    return NonAssetItem(
      id: json['non_asset_id'],
      noSO: json['NoSO'],
      image: json['image'],
      locationCode: json['location_code'],
      nonAssetName: json['non_asset_name'],
      remark: json['remark'],
    );
  }
}
