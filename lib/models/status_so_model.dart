class StatusSO {
  final int id;
  final String status;

  StatusSO({required this.id, required this.status});

  factory StatusSO.fromJson(Map<String, dynamic> json) {
    return StatusSO(
      id: json['id_status'],
      status: json['status'],
    );
  }
}