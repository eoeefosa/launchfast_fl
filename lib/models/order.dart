import 'dart:math';
import 'dart:ui';
import 'cart_item.dart';
import 'user.dart';
import 'store.dart';
export 'cart_item.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  readyForPickup,
  pickingUp,
  onTheWay,
  delivered,
  cancelled,
  outForDelivery,
  queued,
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickingUp:
        return 'Picking Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.queued:
        return 'Queued';
    }
  }

  String get backendName => name.toUpperCase().replaceAll(' ', '_');

  static OrderStatus fromString(String status) {
    final s = status.toUpperCase().replaceAll(' ', '_');
    switch (s) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'PICKING_UP':
        return OrderStatus.pickingUp;
      case 'OUT_FOR_DELIVERY':
      case 'ON_THE_WAY':
        return OrderStatus.onTheWay;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class Order {
  final String id;
  final String? userId;
  final UserProfile? user;
  final List<CartItem> items;
  final double subtotal;
  final double serviceFee;
  final double deliveryFee;
  final double platformDeliveryProfit;
  final double walletDeduction;
  final double total;
  final String deliveryType;
  final OrderStatus status;
  final String date;
  final List<Store> stores;
  final bool isPriority;
  final String? riderId;

  Order({
    required this.id,
    this.userId,
    this.user,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.platformDeliveryProfit,
    required this.walletDeduction,
    required this.total,
    required this.deliveryType,
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
      user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
      items:
          (json['items'] as List?)
              ?.map((i) => CartItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      platformDeliveryProfit: (json['platformDeliveryProfit'] as num?)?.toDouble() ?? 0.0,
      walletDeduction: (json['walletDeduction'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      deliveryType: json['deliveryType']?.toString() ?? 'bulk',
      status: OrderStatusExtension.fromString(json['status']?.toString() ?? ''),
      date: json['date']?.toString() ?? '',
      stores:
          (json['stores'] as List?)
              ?.map((s) {
                if (s is Map<String, dynamic>) {
                  return Store.fromJson(s);
                }
                // Fallback for when only IDs are returned
                return Store(
                  id: s.toString(),
                  name: 'Store ${s.toString().substring(0, min(4, s.toString().length))}',
                  tagline: '',
                  accentColor: const Color(0xFFFF6B2C),
                  deliveryTime: '',
                  rating: 5.0,
                  isOpen: true,
                  deliveryFee: 0,
                  image: '',
                );
              })
              .toList() ??
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
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'deliveryFee': deliveryFee,
      'platformDeliveryProfit': platformDeliveryProfit,
      'walletDeduction': walletDeduction,
      'total': total,
      'deliveryType': deliveryType,
      'status': status.name,
      'date': date,
      'stores': stores.map((s) => s.toJson()).toList(),
      'isPriority': isPriority,
      'riderId': riderId,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    UserProfile? user,
    List<CartItem>? items,
    double? subtotal,
    double? serviceFee,
    double? deliveryFee,
    double? platformDeliveryProfit,
    double? walletDeduction,
    double? total,
    String? deliveryType,
    OrderStatus? status,
    String? date,
    List<Store>? stores,
    bool? isPriority,
    String? riderId,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      platformDeliveryProfit: platformDeliveryProfit ?? this.platformDeliveryProfit,
      walletDeduction: walletDeduction ?? this.walletDeduction,
      total: total ?? this.total,
      deliveryType: deliveryType ?? this.deliveryType,
      status: status ?? this.status,
      date: date ?? this.date,
      stores: stores ?? this.stores,
      isPriority: isPriority ?? this.isPriority,
      riderId: riderId ?? this.riderId,
    );
  }
}
