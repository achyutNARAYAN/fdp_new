import '../../../core/services/cart_order_api_service.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Future<OrderModel> placeOrder({
    required String paymentMode,
    String? deliveryAddressId,
    String deliveryInstructions = '',
  });
  Future<List<OrderModel>> getMyOrders({int page = 1, int limit = 20, String? status});
  Future<OrderModel> getOrderDetails(String orderId);
  Future<void> cancelOrder(String orderId, String reason);
}

class OrderRepositoryImpl implements OrderRepository {
  final CartOrderApiService _apiService;

  OrderRepositoryImpl({CartOrderApiService? apiService})
      : _apiService = apiService ?? cartOrderApiService;

  @override
  Future<OrderModel> placeOrder({
    required String paymentMode,
    String? deliveryAddressId,
    String deliveryInstructions = '',
  }) async {
    final response = await _apiService.checkout(
      paymentMode: paymentMode,
      addressId: deliveryAddressId,
      instructions: deliveryInstructions,
    );
    return OrderModel.fromApi(response);
  }

  @override
  Future<List<OrderModel>> getMyOrders({int page = 1, int limit = 20, String? status}) async {
    final list = await _apiService.getOrders(page: page, limit: limit, status: status);
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => OrderModel.fromApi(json))
        .toList();
  }

  @override
  Future<OrderModel> getOrderDetails(String orderId) async {
    final response = await _apiService.getOrder(orderId);
    return OrderModel.fromApi(response);
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    await _apiService.cancelOrder(orderId, reason);
  }
}

final orderRepository = OrderRepositoryImpl();
