import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/cart_order_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../orders/models/order_model.dart';
import '../orders/providers/order_provider.dart';
import '../../core/services/websocket_tracking_service.dart';

class LiveDeliveryMapScreen extends ConsumerStatefulWidget {
  final String orderId;

  const LiveDeliveryMapScreen({super.key, required this.orderId});

  @override
  ConsumerState<LiveDeliveryMapScreen> createState() =>
      _LiveDeliveryMapScreenState();
}

class _LiveDeliveryMapScreenState extends ConsumerState<LiveDeliveryMapScreen> {
  final MapController _mapController = MapController();
  DriverTrackingModel? _telemetry;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;
  StreamSubscription<DriverLocationEvent>? _driverLocationSub;
  StreamSubscription<OrderUpdateEvent>? _orderUpdateSub;

  @override
  void initState() {
    super.initState();
    _fetchTelemetry();
    wsTrackingService.subscribeOrder(widget.orderId);

    // Live driver GPS coordinates stream via duplex WebSocket
    _driverLocationSub = wsTrackingService.driverLocations.listen((event) {
      if (event.orderId == widget.orderId && mounted) {
        setState(() {
          _telemetry = DriverTrackingModel(
            orderId: event.orderId,
            status: _telemetry?.status ?? 'OUT_FOR_DELIVERY',
            driverName: _telemetry?.driverName ?? 'Delivery Partner',
            driverPhone: _telemetry?.driverPhone ?? '',
            driverVehicle: _telemetry?.driverVehicle ?? 'Motorcycle',
            driverLatitude: event.latitude,
            driverLongitude: event.longitude,
            driverSpeed: event.speed,
            driverHeading: event.heading,
            destinationLat: _telemetry?.destinationLat,
            destinationLng: _telemetry?.destinationLng,
            distanceRemainingKm: _telemetry?.distanceRemainingKm ?? 0.0,
            estimatedTransitMinutes: _telemetry?.estimatedTransitMinutes ?? 0,
          );
          _isLoading = false;
          _errorMessage = null;
        });
        _mapController.move(
          LatLng(event.latitude, event.longitude),
          15.5,
        );
      }
    });

    _orderUpdateSub = wsTrackingService.orderUpdates.listen((event) {
      if (event.orderId == widget.orderId && mounted) {
        ref.read(orderProvider.notifier).fetchOrderById(widget.orderId);
      }
    });

    // Fallback polling every 10s
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchTelemetry(isBackground: true);
    });
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _orderUpdateSub?.cancel();
    wsTrackingService.unsubscribeOrder(widget.orderId);
    _pollingTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchTelemetry({bool isBackground = false}) async {
    try {
      final res = await cartOrderApiService.getDriverTracking(widget.orderId);
      if (mounted) {
        setState(() {
          _telemetry = DriverTrackingModel.fromApi(res);
          _isLoading = false;
          _errorMessage = null;
        });

        // Center map on driver location
        if (!isBackground && _telemetry != null) {
          _mapController.move(
            LatLng(_telemetry!.driverLatitude, _telemetry!.driverLongitude),
            15.0,
          );
        }
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Waiting for driver telemetry to link...';
        });
      }
    }
  }

  void _recenter() {
    if (_telemetry != null) {
      _mapController.move(
        LatLng(_telemetry!.driverLatitude, _telemetry!.driverLongitude),
        15.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = (orderState.activeOrder?.orderId == widget.orderId
            ? orderState.activeOrder
            : orderState.pastOrders
                .where((o) => o.orderId == widget.orderId)
                .firstOrNull) ??
        orderState.activeOrder;

    final LatLng driverPos = _telemetry != null
        ? LatLng(_telemetry!.driverLatitude, _telemetry!.driverLongitude)
        : const LatLng(28.6180, 77.2150);

    final LatLng? destPos = (_telemetry?.destinationLat != null &&
            _telemetry?.destinationLng != null)
        ? LatLng(_telemetry!.destinationLat!, _telemetry!.destinationLng!)
        : null;

    final String? deliveryOtp = order?.deliveryOtp;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          order?.orderNumber != null
              ? 'Tracking #${order!.orderNumber}'
              : 'Live Tracking #${widget.orderId}',
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchTelemetry(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverPos,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fdp',
              ),
              MarkerLayer(
                markers: [
                  // Driver Marker with Heading rotation
                  Marker(
                    point: driverPos,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: (_telemetry?.driverHeading ?? 0.0) * (3.14159 / 180),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            color: AppColors.onPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Destination Marker (Customer Home)
                  if (destPos != null)
                    Marker(
                      point: destPos,
                      width: 44,
                      height: 52,
                      child: const Icon(
                        Icons.pin_drop,
                        color: AppColors.accent,
                        size: 46,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Floating Info Bar (Delivery OTP & Recenter)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (deliveryOtp != null && deliveryOtp.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppDimensions.elevationLevel2,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.vpn_key_rounded,
                          size: 16,
                          color: AppColors.primaryPressed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'OTP: $deliveryOtp',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.primaryPressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                FloatingActionButton.small(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // 3. Bottom Driver & ETA Sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                boxShadow: AppDimensions.elevationLevel3,
                border: Border.all(color: AppColors.neutralLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transit Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Arrival',
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _telemetry != null
                                ? '${_telemetry!.estimatedTransitMinutes} mins'
                                : '6 mins',
                            style: AppTypography.heading1.copyWith(
                              color: AppColors.primaryPressed,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _telemetry != null
                              ? '${_telemetry!.distanceRemainingKm.toStringAsFixed(1)} km away'
                              : '2.1 km away',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPressed,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Driver Profile Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryTint20,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _telemetry?.driverName ?? 'Ramesh Kumar',
                              style: AppTypography.itemName,
                            ),
                            Text(
                              _telemetry?.driverVehicle ??
                                  'Motorcycle (DL01AB1234)',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      if (_telemetry?.driverPhone.isNotEmpty == true)
                        IconButton.filledTonal(
                          icon: const Icon(Icons.phone),
                          color: AppColors.primary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Calling partner: ${_telemetry!.driverPhone}',
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  if (_telemetry?.status.contains('DELIVERED') == true) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.star_outline_rounded),
                        label: const Text('Rate & Review Delivery'),
                        onPressed: () =>
                            context.push('/rate-review/${widget.orderId}'),
                      ),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_isLoading && _telemetry == null)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
