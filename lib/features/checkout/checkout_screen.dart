import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/order_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/badges/diet_marker.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.upi;
  double _selectedTip = 0.0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handlePay() {
    if (_selectedPaymentMethod == PaymentMethodType.cod) {
      context.push('/cod-placement');
    } else {
      context.push('/payment-processing?method=${_selectedPaymentMethod.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final locationState = ref.watch(locationProvider);
    final selectedAddress = locationState.selectedAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout Review'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery Address Card
                  _buildSectionCard(
                    title: 'Delivery Address',
                    actionLabel: 'Change',
                    onAction: () => context.push('/address-selection'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(selectedAddress.title, style: AppTypography.itemName),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(selectedAddress.fullAddress, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Delivery Time Card
                  _buildSectionCard(
                    title: 'Delivery Option',
                    actionLabel: 'Change',
                    onAction: () => context.push('/delivery-time'),
                    content: const Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deliver Now', style: AppTypography.itemName),
                              Text('Confectionery ready in 25–35 min', style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Shop & Items Summary
                  _buildSectionCard(
                    title: cart.shopName ?? 'Confectionery Items',
                    actionLabel: 'Edit Cart',
                    onAction: () => context.pop(),
                    content: Column(
                      children: cart.items.map((ci) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              DietMarker(dietType: ci.item.dietType),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${ci.quantity}x ${ci.item.name} (${ci.selectedVariant.label})',
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(ci.totalPrice),
                                style: AppTypography.itemName.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Note for Delivery Partner
                  _buildSectionCard(
                    title: 'Note for Delivery Partner (Optional)',
                    content: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Leave with gate security / Do not ring bell',
                        hintStyle: AppTypography.bodySmall,
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Delivery Partner Tip Selector (₹0 allowed)
                  _buildSectionCard(
                    title: 'Add Delivery Partner Tip',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '100% of your tip goes to the delivery partner. Tips are non-refundable once delivered.',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [0.0, 20.0, 30.0, 50.0].map((tip) {
                            final isSelected = _selectedTip == tip;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedTip = tip);
                                  ref.read(cartProvider.notifier).setTip(tip);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryTint20 : AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tip == 0.0 ? 'No Tip' : '+₹${tip.toInt()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Payment Method Card
                  _buildSectionCard(
                    title: 'Payment Method',
                    actionLabel: 'Change',
                    onAction: () => context.push('/payment-method'),
                    content: Row(
                      children: [
                        Icon(
                          _selectedPaymentMethod == PaymentMethodType.cod
                              ? Icons.currency_rupee
                              : Icons.account_balance_wallet_outlined,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_selectedPaymentMethod.label, style: AppTypography.itemName),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 7. Price Summary Card
                  _buildSectionCard(
                    title: 'Price Breakdown',
                    content: Column(
                      children: [
                        _priceRow('Item Total', Formatters.formatCurrency(cart.subtotal)),
                        if (cart.discountAmount > 0)
                          _priceRow('Coupon Discount', '-${Formatters.formatCurrency(cart.discountAmount)}',
                              textColor: AppColors.accentPressed),
                        _priceRow('Delivery Partner Fee', Formatters.formatCurrency(cart.deliveryFee)),
                        _priceRow('Confectionery Packaging', Formatters.formatCurrency(cart.packagingFee)),
                        _priceRow('Platform Fee', Formatters.formatCurrency(cart.platformFee)),
                        _priceRow('Taxes (5% GST)', Formatters.formatCurrency(cart.taxes)),
                        if (_selectedTip > 0)
                          _priceRow('Delivery Tip', Formatters.formatCurrency(_selectedTip)),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: AppTypography.heading2),
                            Text(
                              Formatters.formatCurrency(cart.grandTotal),
                              style: AppTypography.price.copyWith(fontSize: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 8. Trust Row
                  const Center(
                    child: Text(
                      'FSSAI Certified Kitchens • Safe Cold-Chain Handover • GST Invoices',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Sticky Bottom Pay CTA
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
                ],
              ),
              child: AppPrimaryButton(
                label: _selectedPaymentMethod == PaymentMethodType.cod
                    ? 'Place COD Order • ${Formatters.formatCurrency(cart.grandTotal)}'
                    : 'Pay ${Formatters.formatCurrency(cart.grandTotal)}',
                onPressed: _handlePay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.itemName.copyWith(fontSize: 15)),
              if (actionLabel != null && onAction != null)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onAction,
                  child: Text(actionLabel, style: const TextStyle(color: AppColors.textPrimary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
