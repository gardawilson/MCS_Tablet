class NoAssetItem {
  final int id;
  final String noSO;
  final String image;
  final String remark;

  NoAssetItem({
    required this.id,
    required this.noSO,
    required this.image,
    required this.remark,
  });

  factory NoAssetItem.fromJson(Map<String, dynamic> json) {
    return NoAssetItem(
      id: json['id_non_asset'],
      noSO: json['NoSO'],
      image: json['image'],
      remark: json['remark'],
    );
  }
}
