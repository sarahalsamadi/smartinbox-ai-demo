class EmailStats {
  final int total;
  final int important;
  final int normal;
  final int ignored;

  EmailStats({
    required this.total,
    required this.important,
    required this.normal,
    required this.ignored,
  });

  factory EmailStats.fromJson(Map<String, dynamic> json) {
    return EmailStats(
      total: json['total'] as int? ?? 0,
      important: json['important'] as int? ?? 0,
      normal: json['normal'] as int? ?? 0,
      ignored: json['ignored'] as int? ?? 0,
    );
  }
}
