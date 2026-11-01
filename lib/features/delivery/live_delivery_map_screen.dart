import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/order_provider.dart';

class LiveDeliveryMapScreen extends ConsumerStatefulWidget {
  final String orderId;

  const LiveDeliveryMapScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<LiveDeliveryMapScreen> createState() => _LiveDeliveryMapScreenState();
}

class _LiveDeliveryMapScreenState extends ConsumerState<LiveDeliveryMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _riderController;

  @override
  void initState() {
    super.initState();
    _riderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _riderController.dispose();
    super.dispose();
  }

  void _callPartner() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusDialog)),
        title: const Text('Call Delivery Partner', style: AppTypography.heading2),
        content: const Text(
          'Connecting through secure masked platform line to Vikram Singh.\nYour personal mobile number remains protected.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dial (Masked)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.activeOrder;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Delivery Tracking'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push('/support'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top 60%: Greyscale map with route and animated partner marker
          Expanded(
            flex: 60,
            child: Stack(
              children: [
                // Custom Greyscale Map with Sage Green route
                Container(
                  color: const Color(0xFFE8ECE9),
                  child: CustomPaint(
                    painter: _LiveRoutePainter(),
                    child: Container(),
                  ),
                ),

                // Animated Delivery Partner Marker (Burnt Amber circle easing along route)
                AnimatedBuilder(
                  animation: _riderController,
                  builder: (context, _) {
                    final t = _riderController.value;
                    final x = 80 + (t * 180);
                    final y = 140 + (t * 120);

                    return Positioned(
                      left: x,
                      top: y,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: AppDimensions.elevationLevel2,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),

                // Destination Pin (Customer Location)
                const Positioned(
                  right: 60,
                  bottom: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: AppColors.textPrimary, size: 36),
                      Text('You', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),

                // Shop Pin
                const Positioned(
                  left: 60,
                  top: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront, color: AppColors.primary, size: 28),
                      Text('Anand Sweets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),

                // Issue Simulation Banner Top Right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => context.push('/delivery-issue/${widget.orderId}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint12,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.report_problem_outlined, size: 14, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('Simulate Issue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom 40%: Draggable details card
          Expanded(
            flex: 40,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusBottomSheet)),
                boxShadow: [
                  BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ETA Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Arriving in', style: AppTypography.caption),
                          Text('14–18 min', style: AppTypography.heading1),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.ac_unit, size: 14, color: AppColors.textPrimary),
                            SizedBox(width: 4),
                            Text('Insulated Thermal Bag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Partner Info Row
                  Row(
                    children: [
                      // 48px Photo
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80'),
                      ),
                      const SizedBox(width: 14),

                      // Name & Vehicle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order?.driverName ?? 'Vikram Singh', style: AppTypography.itemName),
                            const SizedBox(height: 2),
                            Text(
                              order?.driverVehicle ?? 'Electric Scooter (KA-03-EX-4491)',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),

                      // 44px Circular Call button in Sage Green (Masked)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: AppColors.onPrimary, size: 20),
                          onPressed: _callPartner,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Instruction note
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Instructions: ${order?.deliveryInstructions ?? "Leave at doorstep and ring bell"}',
                      style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                    ),
                  ),

                  const Spacer(),

                  // Delivered trigger button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref.read(orderProvider.notifier).setOrderStatus(OrderStatus.delivered);
                        context.go('/order-delivered/${widget.orderId}');
                      },
                      child: const Text('Mark as Delivered (Simulation) →', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final casingPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(70, 130);
    path.lineTo(130, 160);
    path.lineTo(200, 200);
    path.lineTo(260, 260);
    path.lineTo(size.width - 60, size.height - 40);

    // Draw casing then route
    canvas.drawPath(path, casingPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

