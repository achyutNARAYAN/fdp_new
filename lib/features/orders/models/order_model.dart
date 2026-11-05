import 'package:flutter/material.dart';
import '../../cart/models/cart_model.dart';
import '../../item/models/item_model.dart';
import '../../../core/config/api_config.dart';

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
  final String? orderNumber;
  final String? kotNumber;
  final String? deliveryOtp;
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
    this.orderNumber,
    this.kotNumber,
    this.deliveryOtp,
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
    String? deliveryOtp,
    String? orderNumber,
    String? kotNumber,
    List<ProposedChangeItem>? proposedChanges,
    String? cancellationReason,
    double? refundAmount,
    String? refundReference,
    DateTime? refundEta,
  }) {
    return OrderModel(
      orderId: orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      kotNumber: kotNumber ?? this.kotNumber,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
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
        json['id']?.toString() ??
        json['orderId']?.toString() ??
        json['orderNumber']?.toString() ??
        'ORD_${DateTime.now().millisecondsSinceEpoch}';

    final String? orderNumber = json['orderNumber']?.toString();
    final String? kotNumber = json['kotNumber']?.toString();

    final securityOtps = json['securityOtps'] is Map<String, dynamic>
        ? json['securityOtps'] as Map<String, dynamic>
        : null;
    final String? deliveryOtp = securityOtps?['deliveryOtp']?.toString() ??
        json['deliveryOtp']?.toString();

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
    } else if (statusStr.contains('OUT') ||
        statusStr.contains('DELIVERY') ||
        statusStr.contains('ARRIVED')) {
      status = OrderStatus.outForDelivery;
    } else if (statusStr.contains('DELIVERED')) {
      status = OrderStatus.delivered;
    } else if (statusStr.contains('CANCEL')) {
      status = OrderStatus.cancelled;
    } else if (statusStr.contains('DECLINE') ||
        statusStr.contains('REJECT') ||
        statusStr.contains('TIMEOUT')) {
      status = OrderStatus.declined;
    }

    final paymentObj = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : null;

    final payModeStr =
        (paymentObj?['mode'] ?? json['paymentMode'])?.toString().toUpperCase() ??
            '';
    PaymentMethodType method = PaymentMethodType.upi;
    if (payModeStr.contains('COD') || payModeStr.contains('CASH')) {
      method = PaymentMethodType.cod;
    } else if (payModeStr.contains('CARD')) {
      method = PaymentMethodType.card;
    } else if (payModeStr.contains('NET')) {
      method = PaymentMethodType.netBanking;
    }

    final payStatusStr =
        (paymentObj?['status'] ?? json['paymentStatus'])?.toString().toUpperCase() ??
            '';
    PaymentStatus pStatus = method == PaymentMethodType.cod
        ? PaymentStatus.codPending
        : PaymentStatus.paid;
    if (payStatusStr.contains('PAID') || payStatusStr.contains('COMPLETED')) {
      pStatus = PaymentStatus.paid;
    } else if (payStatusStr.contains('PENDING')) {
      pStatus = method == PaymentMethodType.cod
          ? PaymentStatus.codPending
          : PaymentStatus.pending;
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

    final String storeId = json['storeId']?.toString() ??
        json['shopId']?.toString() ??
        storeSnapshot?['_id']?.toString() ??
        '';

    String addressStr = 'Saved Delivery Address';
    final rawAddr = json['deliveryAddress'];
    if (rawAddr is Map<String, dynamic>) {
      final parts = [
        rawAddr['street'] ?? rawAddr['houseNumber'],
        rawAddr['streetArea'],
        rawAddr['city'],
        rawAddr['state'],
        rawAddr['pinCode'] ?? rawAddr['pincode'],
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

    // Resolve items: prefer fallbackItems from current cart, or parse json['items']
    List<CartItemModel> resolvedItems = fallbackItems ?? const [];
    if (resolvedItems.isEmpty && json['items'] is List) {
      final List<CartItemModel> parsedItems = [];
      for (final raw in (json['items'] as List)) {
        if (raw is! Map<String, dynamic>) continue;
        final unit = raw['unit']?.toString() ?? 'PORTION';
        final double price = raw['pricePaise'] != null
            ? ApiConfig.paiseToRupees(raw['pricePaise'])
            : (raw['price'] as num? ?? 0).toDouble();
        final int qty = (raw['quantity'] as num?)?.toInt() ?? 1;
        final String name = raw['name']?.toString() ?? 'Delicacy';
        final String mId = raw['menuItemId']?.toString() ?? '';
        final String? instructions = raw['cookingInstructions']?.toString();

        final variant = ItemVariant(
          id: unit,
          unit: unit,
          label: ApiConfig.formatMeasurementUnit(unit),
          price: price,
          isDefault: true,
        );

        final item = ItemModel(
          id: raw['catalogItemId']?.toString() ?? mId,
          menuItemId: mId,
          shopId: storeId,
          shopName: shopName,
          name: name,
          description: '',
          imageUrl: raw['imageUrl']?.toString() ?? '',
          category: raw['category']?.toString() ?? 'Sweets',
          dietType: ItemModel.parseDietType(raw['dietaryType']?.toString()),
          variants: [variant],
        );

        parsedItems.add(
          CartItemModel(
            id: raw['_id']?.toString() ?? 'item_${mId}_$unit',
            item: item,
            selectedVariant: variant,
            quantity: qty,
            specialInstructions:
                instructions != null && instructions.isNotEmpty
                    ? instructions
                    : null,
          ),
        );
      }
      resolvedItems = parsedItems;
    }

    return OrderModel(
      orderId: id,
      orderNumber: orderNumber,
      kotNumber: kotNumber,
      deliveryOtp: deliveryOtp,
      shopId: storeId,
      shopName: shopName,
      shopAddress: shopAddress,
      fssaiLicense: json['fssaiLicense']?.toString() ?? 'FSSAI: 12723999000142',
      gstin: json['gstin']?.toString() ?? '09AAAFM1234F1Z5',
      items: resolvedItems,
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

/// Real-time Driver GPS Telemetry model
class DriverTrackingModel {
  final String orderId;
  final String status;
  final String driverName;
  final String driverPhone;
  final String driverVehicle;
  final double driverLatitude;
  final double driverLongitude;
  final double driverSpeed;
  final double driverHeading;
  final double? destinationLat;
  final double? destinationLng;
  final double distanceRemainingKm;
  final int estimatedTransitMinutes;

  const DriverTrackingModel({
    required this.orderId,
    required this.status,
    required this.driverName,
    required this.driverPhone,
    required this.driverVehicle,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.driverSpeed,
    required this.driverHeading,
    this.destinationLat,
    this.destinationLng,
    required this.distanceRemainingKm,
    required this.estimatedTransitMinutes,
  });

  factory DriverTrackingModel.fromApi(Map<String, dynamic> json) {
    final driver = json['driver'] is Map<String, dynamic>
        ? json['driver'] as Map<String, dynamic>
        : <String, dynamic>{};
    final location = json['driverLocation'] is Map<String, dynamic>
        ? json['driverLocation'] as Map<String, dynamic>
        : <String, dynamic>{};
    final destination = json['destination'] is Map<String, dynamic>
        ? json['destination'] as Map<String, dynamic>
        : null;
    final coords = destination?['coordinates'] is List
        ? destination!['coordinates'] as List
        : null;
    final metrics = json['metrics'] is Map<String, dynamic>
        ? json['metrics'] as Map<String, dynamic>
        : <String, dynamic>{};

    return DriverTrackingModel(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OUT_FOR_DELIVERY',
      driverName: driver['name']?.toString() ?? 'Delivery Partner',
      driverPhone: driver['phone']?.toString() ?? '',
      driverVehicle: driver['vehicle']?.toString() ?? 'Motorcycle',
      driverLatitude: (location['latitude'] as num?)?.toDouble() ?? 28.6180,
      driverLongitude: (location['longitude'] as num?)?.toDouble() ?? 77.2150,
      driverSpeed: (location['speed'] as num?)?.toDouble() ?? 0.0,
      driverHeading: (location['heading'] as num?)?.toDouble() ?? 0.0,
      destinationLng: coords != null && coords.isNotEmpty
          ? (coords[0] as num?)?.toDouble()
          : null,
      destinationLat: coords != null && coords.length > 1
          ? (coords[1] as num?)?.toDouble()
          : null,
      distanceRemainingKm:
          (metrics['distanceRemainingKm'] as num?)?.toDouble() ?? 0.0,
      estimatedTransitMinutes:
          (metrics['estimatedTransitMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
