import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../data/mock_data.dart';

class OrderState {
  final OrderModel? activeOrder;
  final List<OrderModel> pastOrders;
  final int confirmationCountdownSeconds; // 180 to 0
  final bool isCountdownRunning;
  final String? activeOrderConfirmationPhase; // 'Active Waiting', 'Continuing Confirmation', 'Final Waiting', 'Timeout'

  const OrderState({
    this.activeOrder,
    this.pastOrders = const [],
    this.confirmationCountdownSeconds = 180,
    this.isCountdownRunning = false,
    this.activeOrderConfirmationPhase = 'Active Waiting',
  });

  OrderState copyWith({
    OrderModel? activeOrder,
    List<OrderModel>? pastOrders,
    int? confirmationCountdownSeconds,
    bool? isCountdownRunning,
    String? activeOrderConfirmationPhase,
  }) {
    return OrderState(
      activeOrder: activeOrder ?? this.activeOrder,
      pastOrders: pastOrders ?? this.pastOrders,
      confirmationCountdownSeconds: confirmationCountdownSeconds ?? this.confirmationCountdownSeconds,
      isCountdownRunning: isCountdownRunning ?? this.isCountdownRunning,
      activeOrderConfirmationPhase: activeOrderConfirmationPhase ?? this.activeOrderConfirmationPhase,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  Timer? _countdownTimer;

  OrderNotifier()
      : super(OrderState(
          activeOrder: MockData.getInitialPastOrders().first, // FD10245
          pastOrders: MockData.getInitialPastOrders(),
        ));

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Create a new order from cart & checkout
  OrderModel placeOrder({
    required CartModel cart,
    required PaymentMethodType paymentMethod,
    required String deliveryAddress,
    DateTime? scheduledTime,
  }) {
    final orderId = 'FD${10000 + state.pastOrders.length + 1}';
    final isOnlinePayment = paymentMethod != PaymentMethodType.cod;

    final newOrder = OrderModel(
      orderId: orderId,
      shopId: cart.shopId ?? 'shop_anand',
      shopName: cart.shopName ?? 'Anand Sweets',
      shopAddress: 'Commercial Street, Bengaluru',
      fssaiLicense: '11221334000542',
      gstin: '29AAAAA0000A1Z5',
      items: List.from(cart.items),
      orderStatus: OrderStatus.confirmingOrder,
      paymentStatus: isOnlinePayment ? PaymentStatus.paid : PaymentStatus.codPending,
      paymentMethod: paymentMethod,
      subtotal: cart.subtotal,
      discountAmount: cart.discountAmount,
      deliveryFee: cart.deliveryFee,
      packagingFee: cart.packagingFee,
      platformFee: cart.platformFee,
      taxes: cart.taxes,
      tipAmount: cart.tipAmount,
      totalAmount: cart.grandTotal,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: cart.deliveryInstructions,
      createdAt: DateTime.now(),
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 35)),
      scheduledTime: scheduledTime,
    );

    state = state.copyWith(
      activeOrder: newOrder,
      confirmationCountdownSeconds: 180,
      isCountdownRunning: true,
      activeOrderConfirmationPhase: 'Active Waiting',
    );

    _startCountdown();
    return newOrder;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.confirmationCountdownSeconds <= 1) {
        timer.cancel();
        // Move to Timeout state
        state = state.copyWith(
          confirmationCountdownSeconds: 0,
          isCountdownRunning: false,
          activeOrderConfirmationPhase: 'Timeout',
        );
      } else {
        final remaining = state.confirmationCountdownSeconds - 1;
        String phase = 'Active Waiting';
        if (remaining > 90) {
          phase = 'Active Waiting';
        } else if (remaining > 30) {
          phase = 'Continuing Confirmation';
        } else {
          phase = 'Final Waiting';
        }

        state = state.copyWith(
          confirmationCountdownSeconds: remaining,
          activeOrderConfirmationPhase: phase,
        );
      }
    });
  }

  /// Simulate Shop Confirms the order
  void simulateShopConfirms() {
    _countdownTimer?.cancel();
    if (state.activeOrder != null) {
      final updated = state.activeOrder!.copyWith(
        orderStatus: OrderStatus.orderConfirmed,
      );
      _updateActiveOrder(updated);
    }
  }

  /// Simulate Shop Proposes Changes (Section 6 & Screen 27)
  void simulateShopProposesChanges() {
    _countdownTimer?.cancel();
    if (state.activeOrder != null && state.activeOrder!.items.isNotEmpty) {
      final unavailableItem = state.activeOrder!.items.first;
      final proposed = ProposedChangeItem(
        originalItem: unavailableItem,
        substituteItem: state.activeOrder!.items.length > 1 ? state.activeOrder!.items[1] : null,
        reason: 'Fresh batch of ${unavailableItem.item.name} sold out for the evening.',
        isSubstituteAccepted: false,
      );

      final updated = state.activeOrder!.copyWith(
        orderStatus: OrderStatus.changesProposed,
        proposedChanges: [proposed],
      );
      _updateActiveOrder(updated);
    }
  }

  /// Accept proposed changes
  void acceptProposedChanges() {
    if (state.activeOrder != null) {
      final updated = state.activeOrder!.copyWith(
        orderStatus: OrderStatus.orderConfirmed,
        proposedChanges: [],
      );
      _updateActiveOrder(updated);
    }
  }

  /// Simulate Shop Declines the order (Screen 28)
  void simulateShopDeclines() {
    _countdownTimer?.cancel();
    if (state.activeOrder != null) {
      final isPaid = state.activeOrder!.paymentStatus == PaymentStatus.paid;
      final updated = state.activeOrder!.copyWith(
        orderStatus: OrderStatus.declined,
        paymentStatus: isPaid ? PaymentStatus.refundInitiated : state.activeOrder!.paymentStatus,
        refundAmount: isPaid ? state.activeOrder!.totalAmount : null,
        refundReference: isPaid ? 'REF_${DateTime.now().millisecondsSinceEpoch}' : null,
        refundEta: isPaid ? DateTime.now().add(const Duration(days: 2)) : null,
      );
      _updateActiveOrder(updated);
    }
  }

  /// Try Again on confirmation timeout
  void restartConfirmationWindow() {
    state = state.copyWith(
      confirmationCountdownSeconds: 180,
      isCountdownRunning: true,
      activeOrderConfirmationPhase: 'Active Waiting',
    );
    _startCountdown();
  }

  /// Cancel order safely
  void cancelOrder({required String reason}) {
    _countdownTimer?.cancel();
    if (state.activeOrder != null) {
      final isPaid = state.activeOrder!.paymentStatus == PaymentStatus.paid;
      final updated = state.activeOrder!.copyWith(
        orderStatus: OrderStatus.cancelled,
        cancellationReason: reason,
        paymentStatus: isPaid ? PaymentStatus.refundInitiated : state.activeOrder!.paymentStatus,
        refundAmount: isPaid ? state.activeOrder!.totalAmount : null,
        refundReference: isPaid ? 'REF_CN_${DateTime.now().millisecondsSinceEpoch}' : null,
        refundEta: isPaid ? DateTime.now().add(const Duration(days: 3)) : null,
      );
      _updateActiveOrder(updated);
    }
  }

  /// Step simulation for order tracking
  void setOrderStatus(OrderStatus newStatus) {
    if (state.activeOrder != null) {
      PaymentStatus payment = state.activeOrder!.paymentStatus;
      if (newStatus == OrderStatus.delivered && payment == PaymentStatus.codPending) {
        payment = PaymentStatus.codCollected;
      }
      final updated = state.activeOrder!.copyWith(
        orderStatus: newStatus,
        paymentStatus: payment,
      );
      _updateActiveOrder(updated);
    }
  }

  void _updateActiveOrder(OrderModel updated) {
    final list = state.pastOrders.map((o) => o.orderId == updated.orderId ? updated : o).toList();
    if (!list.any((o) => o.orderId == updated.orderId)) {
      list.insert(0, updated);
    }
    state = state.copyWith(activeOrder: updated, pastOrders: list);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier();
});

