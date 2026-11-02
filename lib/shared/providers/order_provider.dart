import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

class OrderState {
  final OrderModel? activeOrder;
  final List<OrderModel> pastOrders;
  final int confirmationCountdownSeconds; // 180 to 0
  final bool isCountdownRunning;
  final String?
  activeOrderConfirmationPhase; // 'Active Waiting', 'Continuing Confirmation', 'Final Waiting', 'Timeout'

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
      confirmationCountdownSeconds:
          confirmationCountdownSeconds ?? this.confirmationCountdownSeconds,
      isCountdownRunning: isCountdownRunning ?? this.isCountdownRunning,
      activeOrderConfirmationPhase:
          activeOrderConfirmationPhase ?? this.activeOrderConfirmationPhase,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  Timer? _countdownTimer;

  OrderNotifier() : super(const OrderState());

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
