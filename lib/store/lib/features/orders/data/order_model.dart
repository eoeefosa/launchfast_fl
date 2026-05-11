import 'package:flutter/material.dart';

import 'cart_item.dart';
import 'package:campuschow/store/lib/features/auth/data/user_profile.dart';
import 'package:campuschow/store/lib/features/store/data/store_model.dart';
import 'package:campuschow/models/order.dart' show OrderStatus, OrderStatusExtension;
export 'package:campuschow/models/order.dart' show OrderStatus, OrderStatusExtension;
export 'cart_item.dart';

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
    try {
      // id — backend may send 'id' or '_id'
      final rawId = json['id'] ?? json['_id'];
      final resolvedId = rawId is String ? rawId : rawId?.toString() ?? '';

      // date — backend may send 'date', 'createdAt', or 'updatedAt'
      final resolvedDate =
          (json['date'] ?? json['createdAt'] ?? json['updatedAt'])
              ?.toString() ??
          '';

      // stores — backend may send 'stores', 'restaurantIds', or 'restaurantId'
      final rawStores =
          json['stores'] as List? ??
          (json['restaurantIds'] is List
              ? json['restaurantIds'] as List
              : null) ??
          (json['restaurantId'] != null ? [json['restaurantId']] : null) ??
          [];

      return Order(
        id: resolvedId,
        userId: json['userId'] is Map
            ? json['userId']['_id']?.toString() ??
                  json['userId']['id']?.toString()
            : json['userId']?.toString(),
        user: json['user'] != null
            ? UserProfile.fromJson(json['user'])
            : (json['userId'] is Map
                  ? UserProfile.fromJson(json['userId'])
                  : null),
        items:
            (json['items'] as List?)
                ?.map((i) {
                  try {
                    return CartItem.fromJson(i as Map<String, dynamic>);
                  } catch (e, st) {
                    debugPrint('Error parsing CartItem:  $e\\n $st');
                    return null;
                  }
                })
                .whereType<CartItem>()
                .toList() ??
            [],
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
        platformDeliveryProfit:
            (json['platformDeliveryProfit'] as num?)?.toDouble() ?? 0.0,
        walletDeduction: (json['walletDeduction'] as num?)?.toDouble() ?? 0.0,
        total:
            (json['total'] ?? json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        deliveryType: json['deliveryType']?.toString() ?? 'bulk',
        status: OrderStatusExtension.fromString(
          json['status']?.toString() ?? '',
        ),
        date: resolvedDate,
        stores: rawStores.map((s) {
          if (s is Map<String, dynamic>) {
            try {
              return Store.fromJson(s);
            } catch (e, st) {
              debugPrint('Error parsing Store in Order:  $e\\n $st');
              rethrow;
            }
          }
          final sid = s.toString();
          return Store(
            id: sid,
            name: 'Store \${sid.substring(0, sid.length > 4 ? 4 : sid.length)}',
            tagline: '',
            accentColor: '#FF6B2C',
            deliveryTime: '',
            rating: 5.0,
            isOpen: true,
            deliveryFee: 0,
            image: '',
          );
        }).toList(),
        isPriority: json['isPriority'] ?? false,
        riderId: json['riderId'] is Map
            ? json['riderId']['id']?.toString()
            : json['riderId']?.toString(),
      );
    } catch (e, st) {
      debugPrint('CRITICAL ERROR in Order.fromJson: \$e');
      debugPrint('Failed JSON payload: \$json');
      debugPrint(st.toString());
      rethrow;
    }
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
      'stores': stores,
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
      platformDeliveryProfit:
          platformDeliveryProfit ?? this.platformDeliveryProfit,
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
