import 'cart_item.dart';
export 'cart_item.dart';

enum OrderStatus {
  queued,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  waitingInQueue,
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.queued:
        return 'Queued';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.waitingInQueue:
        return 'Waiting In Queue';
    }
  }

  static OrderStatus fromString(String status) {
    final s = status.toUpperCase().replaceAll(' ', '_');
    switch (s) {
      case 'QUEUED':
      case 'PENDING':
      case 'ACCEPTED':
      case 'WAITING_IN_QUEUE':
        return OrderStatus.queued;
      case 'PREPARING':
      case 'READY_FOR_PICKUP':
        return OrderStatus.preparing;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.queued;
    }
  }
}

class Order {
  final String id;
  final String? userId;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final String date;
  final List<String> stores;
  final bool isPriority;
  final String? riderId;

  Order({
    required this.id,
    this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.date,
    required this.stores,
    required this.isPriority,
    this.riderId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is String ? json['id'] : (json['id']?.toString() ?? ''),
      userId: json['userId']?.toString(),
      items: (json['items'] as List)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatusExtension.fromString(json['status']?.toString() ?? ''),
      date: json['date']?.toString() ?? '',
      stores:
          (json['stores'] as List?)?.map<String>((store) {
            if (store is String) return store;
            if (store is Map) {
              return (store['id'] ?? store['_id'] ?? '').toString();
            }
            return store.toString();
          }).toList() ??
          [],
      isPriority: json['isPriority'] ?? false,
      riderId: json['riderId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((i) => i.toJson()).toList(),
      'total': total,
      'status': status.name,
      'date': date,
      'stores': stores,
      'isPriority': isPriority,
      'riderId': riderId,
    };
  }
}
