import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../../cart/models/cart_model.dart';
import '../../../core/services/cart_order_api_service.dart';

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

  /// Loads order history from backend
  Future<void> loadOrders({String? status}) async {
    try {
      final list = await _api.getOrders(status: status);
      if (list.isNotEmpty) {
        final List<OrderModel> fetched = list
            .map((item) {
              if (item is Map<String, dynamic>) {
                return OrderModel.fromApi(item);
              }
              return null;
            })
            .whereType<OrderModel>()
            .toList();

        if (fetched.isNotEmpty) {
          state = state.copyWith(pastOrders: fetched);
        }
      }
    } catch (e) {
      debugPrint('Could not load past orders from API: $e');
    }
  }

  /// Fetches an individual order by ID and updates state
  Future<OrderModel?> fetchOrderById(String orderId) async {
    try {
      final data = await _api.getOrder(orderId);
      if (data.isNotEmpty) {
        final fetched = OrderModel.fromApi(data);
        _updateActiveOrder(fetched);
        return fetched;
      }
    } catch (e) {
      debugPrint('Error fetching order $orderId: $e');
    }
    return state.pastOrders.where((o) => o.orderId == orderId).firstOrNull ??
        (state.activeOrder?.orderId == orderId ? state.activeOrder : null);
  }

  void startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.confirmationCountdownSeconds <= 1) {
        timer.cancel();
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

  /// Places an order from current cart (Flow A)
  Future<OrderModel> placeOrder({
    required CartModel cart,
    required PaymentMethodType paymentMethod,
    required String deliveryAddress,
    String? addressId,
    String deliveryInstructions = '',
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final String paymentMode =
        paymentMethod == PaymentMethodType.cod ? 'COD' : 'ONLINE';

    try {
      final apiResponse = await _api.checkout(
        paymentMode: paymentMode,
        addressId: addressId,
        instructions: deliveryInstructions,
        idempotencyKey: idempotencyKey,
      );

      final createdOrder = OrderModel.fromApi(
        apiResponse,
        fallbackItems: cart.items,
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

      startCountdown();
      return createdOrder;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Direct Order Creation / Buy Now (Flow B)
  Future<OrderModel> placeDirectOrder({
    required String storeId,
    required List<Map<String, dynamic>> items,
    required PaymentMethodType paymentMethod,
    required String deliveryAddress,
    String? addressId,
    String? deliveryInstructions,
    String? couponCode,
    int? tipPaise,
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final String paymentMode =
        paymentMethod == PaymentMethodType.cod ? 'COD' : 'ONLINE';

    try {
      final res = await _api.createDirectOrder(
        storeId: storeId,
        items: items,
        paymentMode: paymentMode,
        deliveryAddressId: addressId,
        deliveryInstructions: deliveryInstructions,
        couponCode: couponCode,
        tipPaise: tipPaise,
        idempotencyKey: idempotencyKey,
      );

      final createdOrder = OrderModel.fromApi(res);

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

      startCountdown();
      return createdOrder;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Step 1: Initiate payment order on gateway
  Future<Map<String, dynamic>> initiateOnlinePayment(
    String orderId, {
    String? idempotencyKey,
  }) async {
    return await _api.initiatePayment(orderId, idempotencyKey: idempotencyKey);
  }

  /// Step 2: Verify payment signature and confirm order
  Future<Map<String, dynamic>> verifyOnlinePayment({
    required String orderId,
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    final result = await _api.verifyPayment(
      orderId: orderId,
      gatewayOrderId: gatewayOrderId,
      gatewayPaymentId: gatewayPaymentId,
      gatewaySignature: gatewaySignature,
    );

    // Update active order to confirmed & paid
    if (state.activeOrder != null && state.activeOrder!.orderId == orderId) {
      final updated = state.activeOrder!.copyWith(
        orderStatus: OrderStatus.orderConfirmed,
        paymentStatus: PaymentStatus.paid,
      );
      _updateActiveOrder(updated);
    } else {
      await fetchOrderById(orderId);
    }

    return result;
  }

  /// Cancel order safely (calls backend API + updates local state)
  Future<void> cancelOrder({
    required String reason,
    String? orderId,
  }) async {
    final targetId = orderId ?? state.activeOrder?.orderId;
    if (targetId != null) {
      await cancelOrderApi(orderId: targetId, reason: reason);
    }
  }

  /// Cancel order via API by explicit order ID
  Future<void> cancelOrderApi({
    required String orderId,
    required String reason,
  }) async {
    _countdownTimer?.cancel();
    try {
      await _api.cancelOrder(orderId, reason);
    } catch (e) {
      debugPrint('API cancel order error: $e');
    }

    final target = state.pastOrders.where((o) => o.orderId == orderId).firstOrNull ??
        (state.activeOrder?.orderId == orderId ? state.activeOrder : null);

    if (target != null) {
      final isPaid = target.paymentStatus == PaymentStatus.paid;
      final updated = target.copyWith(
        orderStatus: OrderStatus.cancelled,
        cancellationReason: reason,
        paymentStatus: isPaid
            ? PaymentStatus.refundInitiated
            : target.paymentStatus,
        refundAmount: isPaid ? target.totalAmount : null,
        refundReference: isPaid
            ? 'REF_CN_${DateTime.now().millisecondsSinceEpoch}'
            : null,
        refundEta: isPaid ? DateTime.now().add(const Duration(days: 3)) : null,
      );
      _updateActiveOrder(updated);
    }
  }

  /// Rate and review order
  Future<void> submitOrderReview({
    required String orderId,
    required int rating,
    required String comment,
    List<String>? foodTags,
    List<Map<String, dynamic>>? itemRatings,
    int? driverRating,
    List<String>? driverTags,
    String? driverComment,
    int? deliveryRating,
    List<Map<String, dynamic>>? dishRatings,
  }) async {
    await _api.submitReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
      foodTags: foodTags,
      itemRatings: itemRatings ?? dishRatings,
      driverRating: driverRating ?? deliveryRating,
      driverTags: driverTags,
      driverComment: driverComment,
    );
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
    startCountdown();
  }

  void _updateActiveOrder(OrderModel updated) {
    final list = state.pastOrders
        .map((o) => o.orderId == updated.orderId ? updated : o)
        .toList();
    if (!list.any((o) => o.orderId == updated.orderId)) {
      list.insert(0, updated);
    }
    state = state.copyWith(
      activeOrder:
          state.activeOrder?.orderId == updated.orderId ? updated : state.activeOrder,
      pastOrders: list,
    );
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier();
});
