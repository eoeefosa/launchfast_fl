class StoreStats {
  final double revenue;
  final double foodRevenue;
  final double deliveryRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int preparingOrders;
  final Map<String, int> topSellingItems;

  StoreStats({
    required this.revenue,
    required this.foodRevenue,
    required this.deliveryRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.topSellingItems,
  });

  factory StoreStats.fromJson(Map<String, dynamic> json) {
    return StoreStats(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      foodRevenue: (json['foodRevenue'] as num?)?.toDouble() ?? 0.0,
      deliveryRevenue: (json['deliveryRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      preparingOrders: json['preparingOrders'] as int? ?? 0,
      topSellingItems: json['topSellingItems'] != null 
          ? Map<String, int>.from(json['topSellingItems']) 
          : {},
    );
  }
}
