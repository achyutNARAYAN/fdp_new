import 'package:flutter/material.dart';
import 'cart_model.dart';

enum OrderStatus {
  orderPlaced('Order Placed', Icons.receipt_long),
  confirmingOrder('Confirming Order', Icons.hourglass_top),
  changesProposed('Changes Proposed', Icons.announcement),
  orderConfirmed('Order Confirmed', Icons.check_circle),
  scheduled('Scheduled', Icons.event),
  preparing('Preparing', Icons.outdoor_grill),
  readyForPickup('Ready for Pickup', Icons.inventory_2),
  driverAssigned('Driver Assigned', Icons.person_pin_circle),
  pickedUp('Picked Up', Icons.takeout_dining),
  outForDelivery('Out for Delivery', Icons.delivery_dining),
  delivered('Delivered', Icons.task_alt),
  deliveryFailed('Delivery Failed', Icons.error_outline),
  declined('Declined', Icons.cancel_outlined),
  cancelled('Cancelled', Icons.close),
  returned('Returned', Icons.assignment_return);

  final String label;
  final IconData icon;
  const OrderStatus(this.label, this.icon);
}

enum PaymentStatus {
  pending('Payment Pending', Icons.pending),
  processing('Processing', Icons.sync),
  paid('Paid', Icons.verified),
  failed('Payment Failed', Icons.error),
  codPending('COD Pending', Icons.currency_rupee),
  codCollected('COD Collected', Icons.check_circle),
  refundInitiated('Refund Initiated', Icons.history),
  refundCompleted('Refund Completed', Icons.check_circle_outline);

  final String label;
  final IconData icon;
  const PaymentStatus(this.label, this.icon);
}

enum PaymentMethodType {
  upi('UPI (Google Pay, PhonePe, Paytm)'),
  card('Credit / Debit Card'),
  netBanking('Net Banking'),
  wallet('Mobile Wallet'),
  cod('Cash on Delivery (COD)');

  final String label;
  const PaymentMethodType(this.label);
}

class ProposedChangeItem {
  final CartItemModel originalItem;
  final CartItemModel? substituteItem;
  final String reason;
  final bool isSubstituteAccepted;

  const ProposedChangeItem({
    required this.originalItem,
    this.substituteItem,
    required this.reason,
    this.isSubstituteAccepted = false,
  });

  ProposedChangeItem copyWith({bool? isSubstituteAccepted}) {
    return ProposedChangeItem(
      originalItem: originalItem,
      substituteItem: substituteItem,
      reason: reason,
      isSubstituteAccepted: isSubstituteAccepted ?? this.isSubstituteAccepted,
    );
  }
}

class OrderModel {
  final String orderId;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final String fssaiLicense;
  final String gstin;
  final List<CartItemModel> items;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final PaymentMethodType paymentMethod;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final double packagingFee;
  final double platformFee;
  final double taxes;
  final double tipAmount;
  final double totalAmount;
  final String deliveryAddress;
  final String? deliveryInstructions;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? scheduledTime;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final String? driverPhotoUrl;
  final List<ProposedChangeItem> proposedChanges;
  final String? cancellationReason;
  final double? refundAmount;
  final String? refundReference;
  final DateTime? refundEta;

  const OrderModel({
    required this.orderId,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.fssaiLicense,
    required this.gstin,
    required this.items,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.packagingFee,
    required this.platformFee,
    required this.taxes,
    required this.tipAmount,
    required this.totalAmount,
    required this.deliveryAddress,
    this.deliveryInstructions,
    required this.createdAt,
    this.estimatedDeliveryTime,
    this.scheduledTime,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverPhotoUrl,
    this.proposedChanges = const [],
    this.cancellationReason,
    this.refundAmount,
    this.refundReference,
    this.refundEta,
  });

  bool get isCancellable {
    // Free while confirming or before prep begins
    return orderStatus == OrderStatus.confirmingOrder ||
        orderStatus == OrderStatus.orderPlaced ||
        orderStatus == OrderStatus.orderConfirmed;
  }

  bool get isScheduled => scheduledTime != null;

  OrderModel copyWith({
    OrderStatus? orderStatus,
    PaymentStatus? paymentStatus,
    DateTime? estimatedDeliveryTime,
    String? driverName,
    String? driverPhone,
    String? driverVehicle,
    List<ProposedChangeItem>? proposedChanges,
    String? cancellationReason,
    double? refundAmount,
    String? refundReference,
    DateTime? refundEta,
  }) {
    return OrderModel(
      orderId: orderId,
      shopId: shopId,
      shopName: shopName,
      shopAddress: shopAddress,
      fssaiLicense: fssaiLicense,
      gstin: gstin,
      items: items,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discountAmount: discountAmount,
      deliveryFee: deliveryFee,
      packagingFee: packagingFee,
      platformFee: platformFee,
      taxes: taxes,
      tipAmount: tipAmount,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      createdAt: createdAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      scheduledTime: scheduledTime,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverVehicle: driverVehicle ?? this.driverVehicle,
      driverPhotoUrl: driverPhotoUrl,
      proposedChanges: proposedChanges ?? this.proposedChanges,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReference: refundReference ?? this.refundReference,
      refundEta: refundEta ?? this.refundEta,
    );
  }

  factory OrderModel.fromApi(
    Map<String, dynamic> json, {
    List<CartItemModel>? fallbackItems,
  }) {
    final id = json['_id']?.toString() ??
        json['orderNumber']?.toString() ??
        json['id']?.toString() ??
        json['orderId']?.toString() ??
        'ORD_${DateTime.now().millisecondsSinceEpoch}';

    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : <String, dynamic>{};

    final double subtotal = pricing['itemsSubtotalPaise'] != null
        ? (pricing['itemsSubtotalPaise'] as num) / 100
        : (pricing['subtotalPaise'] != null
            ? (pricing['subtotalPaise'] as num) / 100
            : (json['subtotal'] as num? ?? 0).toDouble());

    final double discount = pricing['discountPaise'] != null
        ? (pricing['discountPaise'] as num) / 100
        : (json['discountAmount'] as num? ?? 0).toDouble();

    final double delivery = pricing['deliveryFeePaise'] != null
        ? (pricing['deliveryFeePaise'] as num) / 100
        : (json['deliveryFee'] as num? ?? 0).toDouble();

    final double packaging = pricing['packagingFeePaise'] != null
        ? (pricing['packagingFeePaise'] as num) / 100
        : (json['packagingFee'] as num? ?? 0).toDouble();

    final double platform = pricing['platformFeePaise'] != null
        ? (pricing['platformFeePaise'] as num) / 100
        : (json['platformFee'] as num? ?? 0).toDouble();

    final double taxes = pricing['totalGstPaise'] != null
        ? (pricing['totalGstPaise'] as num) / 100
        : (json['taxes'] as num? ?? 0).toDouble();

    final double tip = pricing['tipPaise'] != null
        ? (pricing['tipPaise'] as num) / 100
        : (json['tipAmount'] as num? ?? 0).toDouble();

    final double total = pricing['grandTotalPaise'] != null
        ? (pricing['grandTotalPaise'] as num) / 100
        : (pricing['totalPaise'] != null
            ? (pricing['totalPaise'] as num) / 100
            : (json['totalAmount'] as num? ??
                    (subtotal + delivery + packaging + platform + taxes + tip - discount))
                .toDouble());

    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    OrderStatus status = OrderStatus.confirmingOrder;
    if (statusStr.contains('CONFIRMED') || statusStr.contains('ACCEPTED')) {
      status = OrderStatus.orderConfirmed;
    } else if (statusStr.contains('PREPARING')) {
      status = OrderStatus.preparing;
    } else if (statusStr.contains('READY')) {
      status = OrderStatus.readyForPickup;
    } else if (statusStr.contains('DRIVER') || statusStr.contains('PICKED')) {
      status = OrderStatus.pickedUp;
    } else if (statusStr.contains('OUT') || statusStr.contains('DELIVERY') || statusStr.contains('ARRIVED')) {
      status = OrderStatus.outForDelivery;
    } else if (statusStr.contains('DELIVERED')) {
      status = OrderStatus.delivered;
    } else if (statusStr.contains('CANCEL')) {
      status = OrderStatus.cancelled;
    } else if (statusStr.contains('DECLINE') || statusStr.contains('REJECT') || statusStr.contains('TIMEOUT')) {
      status = OrderStatus.declined;
    }

    final paymentObj = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : null;

    final payModeStr = (paymentObj?['mode'] ?? json['paymentMode'])?.toString().toUpperCase() ?? '';
    PaymentMethodType method = PaymentMethodType.upi;
    if (payModeStr.contains('COD') || payModeStr.contains('CASH')) {
      method = PaymentMethodType.cod;
    } else if (payModeStr.contains('CARD')) {
      method = PaymentMethodType.card;
    } else if (payModeStr.contains('NET')) {
      method = PaymentMethodType.netBanking;
    }

    final payStatusStr = (paymentObj?['status'] ?? json['paymentStatus'])?.toString().toUpperCase() ?? '';
    PaymentStatus pStatus = method == PaymentMethodType.cod
        ? PaymentStatus.codPending
        : PaymentStatus.paid;
    if (payStatusStr.contains('PAID') || payStatusStr.contains('COMPLETED')) {
      pStatus = PaymentStatus.paid;
    } else if (payStatusStr.contains('FAIL')) {
      pStatus = PaymentStatus.failed;
    } else if (payStatusStr.contains('REFUND')) {
      pStatus = PaymentStatus.refundInitiated;
    }

    final storeSnapshot = json['storeSnapshot'] is Map<String, dynamic>
        ? json['storeSnapshot'] as Map<String, dynamic>
        : null;
    final storeAddress = storeSnapshot?['address'] is Map<String, dynamic>
        ? storeSnapshot!['address'] as Map<String, dynamic>
        : null;
    final String shopAddress = storeAddress != null
        ? [storeAddress['street'], storeAddress['city'], storeAddress['pinCode']]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .join(', ')
        : (json['shopAddress']?.toString() ?? 'Civil Lines, Lucknow');

    final String shopName = storeSnapshot?['name']?.toString() ??
        storeSnapshot?['tradeName']?.toString() ??
        json['storeName']?.toString() ??
        json['shopName']?.toString() ??
        'Mishra Ji Sweets';

    String addressStr = 'Saved Delivery Address';
    final rawAddr = json['deliveryAddress'];
    if (rawAddr is Map<String, dynamic>) {
      final parts = [
        rawAddr['houseNumber'],
        rawAddr['streetArea'],
        rawAddr['city'],
        rawAddr['state'],
        rawAddr['pincode'],
      ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

      addressStr = parts.isNotEmpty
          ? parts.join(', ')
          : (rawAddr['fullAddress']?.toString() ??
              rawAddr['address']?.toString() ??
              rawAddr['title']?.toString() ??
              addressStr);
    } else if (rawAddr is String && rawAddr.isNotEmpty) {
      addressStr = rawAddr;
    }

    final dateStr = json['createdAt']?.toString();
    DateTime createdAt = DateTime.now();
    if (dateStr != null) {
      createdAt = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    return OrderModel(
      orderId: id,
      shopId: json['storeId']?.toString() ?? json['shopId']?.toString() ?? '',
      shopName: shopName,
      shopAddress: shopAddress,
      fssaiLicense: json['fssaiLicense']?.toString() ?? 'FSSAI: 12723999000142',
      gstin: json['gstin']?.toString() ?? '09AAAFM1234F1Z5',
      items: fallbackItems ?? const [],
      orderStatus: status,
      paymentStatus: pStatus,
      paymentMethod: method,
      subtotal: subtotal,
      discountAmount: discount,
      deliveryFee: delivery,
      packagingFee: packaging,
      platformFee: platform,
      taxes: taxes,
      tipAmount: tip,
      totalAmount: total,
      deliveryAddress: addressStr,
      deliveryInstructions: json['deliveryInstructions']?.toString(),
      createdAt: createdAt,
      estimatedDeliveryTime: createdAt.add(const Duration(minutes: 35)),
    );
  }
}
