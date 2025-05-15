class StatusSO {
  final int id;
  final String status;

  StatusSO({required this.id, required this.status});

  // factory constructor dari JSON (jika ada)
  factory StatusSO.fromJson(Map<String, dynamic> json) {
    return StatusSO(
      id: json['id_status'],
      status: json['status'],
    );
  }

  // method copyWith untuk update sebagian properti
  StatusSO copyWith({
    int? id,
    String? status,
  }) {
    return StatusSO(
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }
}
