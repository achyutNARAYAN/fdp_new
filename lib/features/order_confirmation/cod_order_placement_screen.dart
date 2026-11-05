import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/core/providers/location_provider.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/badges/status_chip.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class CodOrderPlacementScreen extends ConsumerStatefulWidget {
  const CodOrderPlacementScreen({super.key});

  @override
  ConsumerState<CodOrderPlacementScreen> createState() =>
      _CodOrderPlacementScreenState();
}

class _CodOrderPlacementScreenState
    extends ConsumerState<CodOrderPlacementScreen> {
  bool _isPlacing = false;

  Future<void> _handlePlaceCodOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      context.go('/cart');
      return;
    }

    setState(() => _isPlacing = true);
    final location = ref.read(locationProvider);
    final deliveryAddress = location.selectedAddress?.fullAddress ??
        location.selectedAddress?.title ??
        'Hazratganj, Lucknow, UP';

    try {
      final order = await ref.read(orderProvider.notifier).placeOrder(
            cart: cart,
            paymentMethod: PaymentMethodType.cod,
            deliveryAddress: deliveryAddress,
            addressId: location.selectedAddress?.id,
          );

      await ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      setState(() => _isPlacing = false);
      context.go('/waiting-confirmation/${order.orderId}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cash on Delivery Order'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(
                label: 'Cash Payment at Doorstep',
                type: StatusChipType.success,
              ),
              const SizedBox(height: 16),

              const Text('Cash on Delivery', style: AppTypography.heading1),
              const SizedBox(height: 8),

              const Text(
                'Your sweet treat order will be sent to the shop for instant confirmation.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),

              // Keep exact change info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exact Cash Collection',
                            style: AppTypography.itemName,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Please keep ${Formatters.formatCurrency(cart.grandTotal)} ready at handover.',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.neutralLight),
                ),
                child: Column(
                  children: [
                    _row('Shop', cart.shopName?.isNotEmpty == true ? cart.shopName! : 'Selected Store'),
                    _row('Total Items', '${cart.totalItemCount} items'),
                    _row(
                      'Delivery Address',
                      location.selectedAddress?.title ?? 'Saved Address',
                    ),
                    _row(
                      'Amount to Pay',
                      Formatters.formatCurrency(cart.grandTotal),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppPrimaryButton(
                isLoading: _isPlacing,
                label: 'Confirm & Place COD Order',
                onPressed: _isPlacing ? null : _handlePlaceCodOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Flexible(
            child: Text(
              value,
              style: AppTypography.itemName.copyWith(fontSize: 14),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
