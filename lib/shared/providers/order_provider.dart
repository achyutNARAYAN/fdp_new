import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../../core/services/cart_order_api_service.dart';

class OrderState {
  final OrderModel? activeOrder;
  final List<OrderModel> pastOrders;
  final int confirmationCountdownSeconds; // 180 to 0
  final bool isCountdownRunning;
  final String? activeOrderConfirmationPhase; // 'Active Waiting', 'Continuing Confirmation', 'Final Waiting', 'Timeout'
  final bool isLoading;
  final String? errorMessage;

  const OrderState({
    this.activeOrder,
    this.pastOrders = const [],
    this.confirmationCountdownSeconds = 180,
    this.isCountdownRunning = false,
    this.activeOrderConfirmationPhase = 'Active Waiting',
    this.isLoading = false,
    this.errorMessage,
  });

  OrderState copyWith({
    OrderModel? activeOrder,
    List<OrderModel>? pastOrders,
    int? confirmationCountdownSeconds,
    bool? isCountdownRunning,
    String? activeOrderConfirmationPhase,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderState(
      activeOrder: activeOrder ?? this.activeOrder,
      pastOrders: pastOrders ?? this.pastOrders,
      confirmationCountdownSeconds:
          confirmationCountdownSeconds ?? this.confirmationCountdownSeconds,
      isCountdownRunning: isCountdownRunning ?? this.isCountdownRunning,
      activeOrderConfirmationPhase:
          activeOrderConfirmationPhase ?? this.activeOrderConfirmationPhase,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final CartOrderApiService _api;
  Timer? _countdownTimer;

  OrderNotifier({CartOrderApiService? api})
      : _api = api ?? cartOrderApiService,
        super(const OrderState()) {
    loadOrders();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> loadOrders() async {
    try {
      final list = await _api.getOrders();
      if (list.isNotEmpty) {
        final List<OrderModel> fetched = list.map((item) {
          if (item is Map<String, dynamic>) {
            return OrderModel.fromApi(item);
          }
          return null;
        }).whereType<OrderModel>().toList();

        if (fetched.isNotEmpty) {
          state = state.copyWith(pastOrders: fetched);
        }
      }
    } catch (e) {
      debugPrint('Could not load past orders from API: $e');
    }
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

  /// Places a new order via API and updates the local state
  Future<OrderModel> placeOrder({
    required CartModel cart,
    required PaymentMethodType paymentMethod,
    required String deliveryAddress,
    String? addressId,
    String deliveryInstructions = '',
    String? razorpayPaymentId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final String paymentMode =
        paymentMethod == PaymentMethodType.cod ? 'COD' : 'ONLINE';

    Map<String, dynamic>? apiResponse;
    try {
      apiResponse = await _api.checkout(
        paymentMode: paymentMode,
        addressId: addressId,
        instructions: deliveryInstructions,
      );
    } catch (e) {
      debugPrint('API checkout error: $e. Creating local session order.');
    }

    final createdOrder = apiResponse != null && apiResponse.isNotEmpty
        ? OrderModel.fromApi(apiResponse, fallbackItems: cart.items)
        : OrderModel(
            orderId: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
            shopId: cart.shopId ?? 'shop_1',
            shopName: cart.shopName ?? 'Mishra Ji Sweets',
            shopAddress: 'Civil Lines, Lucknow',
            fssaiLicense: 'FSSAI: 12723999000142',
            gstin: '09AAAFM1234F1Z5',
            items: List.from(cart.items),
            orderStatus: OrderStatus.confirmingOrder,
            paymentStatus: paymentMethod == PaymentMethodType.cod
                ? PaymentStatus.codPending
                : PaymentStatus.paid,
            paymentMethod: paymentMethod,
            subtotal: cart.subtotal,
            discountAmount: cart.discountAmount,
            deliveryFee: cart.deliveryFee ?? 0.0,
            packagingFee: cart.packagingFee ?? 0.0,
            platformFee: cart.platformFee ?? 0.0,
            taxes: cart.taxes ?? 0.0,
            tipAmount: 0.0,
            totalAmount: cart.grandTotal,
            deliveryAddress: deliveryAddress,
            deliveryInstructions:
                deliveryInstructions.isNotEmpty ? deliveryInstructions : null,
            createdAt: DateTime.now(),
            estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 35)),
          );

    _countdownTimer?.cancel();
    final updatedPast = List<OrderModel>.from(state.pastOrders);
    updatedPast.removeWhere((o) => o.orderId == createdOrder.orderId);
    updatedPast.insert(0, createdOrder);

    state = state.copyWith(
      activeOrder: createdOrder,
      pastOrders: updatedPast,
      confirmationCountdownSeconds: 180,
      isCountdownRunning: true,
      activeOrderConfirmationPhase: 'Active Waiting',
      isLoading: false,
    );

    _startCountdown();
    return createdOrder;
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
        paymentStatus: isPaid
            ? PaymentStatus.refundInitiated
            : state.activeOrder!.paymentStatus,
        refundAmount: isPaid ? state.activeOrder!.totalAmount : null,
        refundReference: isPaid
            ? 'REF_CN_${DateTime.now().millisecondsSinceEpoch}'
            : null,
        refundEta: isPaid ? DateTime.now().add(const Duration(days: 3)) : null,
      );
      _updateActiveOrder(updated);
    }
  }

  void _updateActiveOrder(OrderModel updated) {
    final list = state.pastOrders
        .map((o) => o.orderId == updated.orderId ? updated : o)
        .toList();
    if (!list.any((o) => o.orderId == updated.orderId)) {
      list.insert(0, updated);
    }
    state = state.copyWith(activeOrder: updated, pastOrders: list);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier();
});
