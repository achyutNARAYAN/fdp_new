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
}
