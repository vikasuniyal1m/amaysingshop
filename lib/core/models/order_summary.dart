class OrderSummary {
  OrderSummary({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
  });

  final int id;
  final String status;
  final String total;
  final String currency;
  final DateTime createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      total: json['total'] as String? ?? '0',
      currency: json['currency'] as String? ?? 'USD',
      createdAt: DateTime.tryParse(json['date_created'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
