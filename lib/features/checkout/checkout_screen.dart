import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/services/razorpay_service.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/idempotency_utils.dart';
import 'package:fdp/features/orders/models/order_model.dart';
import 'package:fdp/features/auth/providers/auth_provider.dart';
import 'package:fdp/features/cart/providers/cart_provider.dart';
import 'package:fdp/core/models/address_model.dart';
import 'package:fdp/features/checkout/providers/address_provider.dart';
import 'package:fdp/core/providers/location_provider.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/badges/diet_marker.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();
  final RazorpayService _razorpayService = RazorpayService();
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.upi;
  bool _isProcessing = false;
  String? _pendingOrderId;
  String? _pendingGatewayOrderId;
  String? _checkoutIdempotencyKey;

  String _getCheckoutIdempotencyKey() {
    if (_checkoutIdempotencyKey != null) return _checkoutIdempotencyKey!;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return _checkoutIdempotencyKey =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void initState() {
    super.initState();
    _razorpayService.initialize(
      onSuccess: _handleRazorpaySuccess,
      onError: _handleRazorpayError,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (_pendingOrderId == null) return;
    if (mounted) setState(() => _isProcessing = true);

    try {
      // Step 2: Verify Payment Signature on backend
      final gatewayOrderId =
          response.orderId ?? _pendingGatewayOrderId ?? '';
      final gatewayPaymentId = response.paymentId ?? '';
      final gatewaySignature = response.signature ?? '';

      await ref.read(orderProvider.notifier).verifyOnlinePayment(
            orderId: _pendingOrderId!,
            gatewayOrderId: gatewayOrderId,
            gatewayPaymentId: gatewayPaymentId,
            gatewaySignature: gatewaySignature,
          );

      // Empty cart after successful verification
      await ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final confirmedId = _pendingOrderId!;
      _pendingOrderId = null;
      _pendingGatewayOrderId = null;
      _checkoutIdempotencyKey = null;

      // Navigate to live waiting confirmation screen
      context.go('/waiting-confirmation/$confirmedId');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification failed: $e'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message != null && response.message!.isNotEmpty
              ? 'Payment: ${response.message}'
              : 'Payment was cancelled or failed. You can retry anytime.',
        ),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Future<void> _handleProceedToPay() async {
    if (_isProcessing) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    final locationState = ref.read(locationProvider);
    final savedAddresses = ref.read(addressListProvider);
    final selectedAddr = locationState.selectedAddress ??
        savedAddresses.where((a) => a.isDefault).firstOrNull ??
        savedAddresses.firstOrNull;

    if (selectedAddr == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add or select a delivery address to proceed.'),
            backgroundColor: AppColors.accent,
          ),
        );
        context.push('/address-selection');
      }
      return;
    }

    final address = selectedAddr.fullAddress.isNotEmpty
        ? selectedAddr.fullAddress
        : selectedAddr.title;

    final userNote = _noteController.text.trim();
    final effectiveInstructions = userNote.isNotEmpty
        ? userNote
        : (selectedAddr.deliveryInstructions?.trim().isNotEmpty == true
            ? selectedAddr.deliveryInstructions!.trim()
            : 'Call when you reach gate');

    if (_selectedPaymentMethod == PaymentMethodType.cod) {
      // Direct Cash on Delivery placement
      setState(() => _isProcessing = true);
      await _placeCodOrderAndNavigate(
        selectedAddr: selectedAddr,
        address: address,
        instructions: effectiveInstructions,
      );
    } else {
      // Online Payment (2-Step Lifecycle: Checkout -> Initiate -> Gateway -> Verify)
      setState(() => _isProcessing = true);
      final authState = ref.read(authProvider);

      try {
        // Step 1: Create Order on backend with ONLINE mode (PAYMENT_PENDING)
        final checkoutIdempotencyKey = IdempotencyUtils.generateKey();
        final createdOrder = await ref.read(orderProvider.notifier).placeOrder(
              cart: cart,
              paymentMethod: _selectedPaymentMethod,
              deliveryAddress: address,
              addressId: selectedAddr?.id,
              deliveryInstructions: _noteController.text.trim(),
              idempotencyKey: _getCheckoutIdempotencyKey(),
            );

        _pendingOrderId = createdOrder.orderId;

        // Step 2: Initiate Payment Order with Gateway
        final paymentIdempotencyKey = IdempotencyUtils.generateKey();
        final initData = await ref
            .read(orderProvider.notifier)
            .initiateOnlinePayment(
              createdOrder.orderId,
              idempotencyKey: paymentIdempotencyKey,
            );

        final gatewayOrderId = (initData['gatewayOrderId'] ??
                initData['razorpayOrderId'] ??
                initData['id'])
            ?.toString();
        if (gatewayOrderId == null || gatewayOrderId.isEmpty) {
          throw StateError('Payment gateway did not return an order ID.');
        }
        _pendingGatewayOrderId = gatewayOrderId;
        final String? keyId = initData['keyId']?.toString();
        final int? amountPaise = (initData['amountPaise'] as num?)?.toInt();

        if (!mounted) return;

        // Step 3: Open Razorpay checkout dialog
        await _razorpayService.openCheckout(
          shopName: cart.shopName?.isNotEmpty == true ? cart.shopName! : 'Store Order',
          gatewayOrderId: gatewayOrderId,
          amountPaise:
              amountPaise ?? ApiConfig.rupeesToPaise(cart.grandTotal),
          keyId: keyId,
          userEmail: authState.user?.email,
          userPhone: authState.phoneNumber,
          orderDescription:
              'Order #${createdOrder.orderNumber ?? createdOrder.orderId}',
        );

        if (mounted) {
          setState(() => _isProcessing = false);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _pendingOrderId = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not initiate online payment: $e'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  Future<void> _placeCodOrderAndNavigate({
    required AddressModel selectedAddr,
    required String address,
    required String instructions,
  }) async {
    final cart = ref.read(cartProvider);

    try {
      final createdOrder = await ref.read(orderProvider.notifier).placeOrder(
            cart: cart,
            paymentMethod: PaymentMethodType.cod,
            deliveryAddress: address,
            addressId: selectedAddr?.id,
            deliveryInstructions: _noteController.text.trim(),
            idempotencyKey: _getCheckoutIdempotencyKey(),
          );

      // Empty the cart after successful order creation
      await ref.read(cartProvider.notifier).clearCart();
      _checkoutIdempotencyKey = null;

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Navigate to live waiting confirmation screen
      context.go('/waiting-confirmation/${createdOrder.orderId}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not place COD order: $e'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final locationState = ref.watch(locationProvider);
    final savedAddresses = ref.watch(addressListProvider);
    final selectedAddress = locationState.selectedAddress ??
        savedAddresses.where((a) => a.isDefault).firstOrNull ??
        savedAddresses.firstOrNull;

    if (locationState.selectedAddress == null && selectedAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(locationProvider).selectedAddress == null) {
          ref.read(locationProvider.notifier).selectAddress(selectedAddress);
        }
      });
    }

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
                    actionLabel: selectedAddress != null ? 'Change' : 'Add Address',
                    onAction: () => context.push('/address-selection'),
                    content: selectedAddress != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedAddress.title.isNotEmpty
                                          ? selectedAddress.title
                                          : 'Delivery Address',
                                      style: AppTypography.itemName,
                                    ),
                                  ),
                                  if (selectedAddress.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTint20,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedAddress.fullAddress,
                                style: AppTypography.bodySmall,
                              ),
                              if (selectedAddress.deliveryInstructions?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Note: ${selectedAddress.deliveryInstructions}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.add_location_alt_outlined,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No delivery address selected. Tap to add or select.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
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
                              Text(
                                'Standard Delivery (30-45 mins)',
                                style: AppTypography.itemName,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Fresh handover directly from the confectionery kitchen',
                                style: AppTypography.caption,
                              ),
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
                                style: AppTypography.itemName.copyWith(
                                  fontSize: 14,
                                ),
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
                        hintText:
                            'e.g. Leave with gate security / Do not ring bell',
                        hintStyle: AppTypography.bodySmall,
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Payment Method Selection (Razorpay & COD)
                  _buildSectionCard(
                    title: 'Payment Method',
                    content: Column(
                      children: [
                        // Razorpay Option (UPI / Cards / NetBanking)
                        _buildPaymentOptionTile(
                          title: 'Razorpay Online (UPI, Cards, NetBanking)',
                          subtitle:
                              'GPay, PhonePe, Paytm, Visa, Mastercard, NetBanking',
                          type: PaymentMethodType.upi,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const Divider(height: 16),
                        // Cash on Delivery Option
                        _buildPaymentOptionTile(
                          title: 'Cash on Delivery (COD)',
                          subtitle:
                              'Pay cash to the delivery executive upon arrival',
                          type: PaymentMethodType.cod,
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Price Summary Card
                  _buildSectionCard(
                    title: 'Price Breakdown',
                    content: Column(
                      children: [
                        _priceRow(
                          'Item Total',
                          Formatters.formatCurrency(cart.subtotal),
                        ),
                        if (cart.discountAmount > 0)
                          _priceRow(
                            'Coupon Discount',
                            '-${Formatters.formatCurrency(cart.discountAmount)}',
                            textColor: AppColors.accentPressed,
                          ),
                        if (cart.deliveryFee != null)
                          _priceRow(
                            'Delivery Partner Fee',
                            Formatters.formatCurrency(cart.deliveryFee!),
                          ),
                        if (cart.packagingFee != null)
                          _priceRow(
                            'Confectionery Packaging',
                            Formatters.formatCurrency(cart.packagingFee!),
                          ),
                        if (cart.platformFee != null)
                          _priceRow(
                            'Platform Fee',
                            Formatters.formatCurrency(cart.platformFee!),
                          ),
                        if (cart.taxes != null)
                          _priceRow(
                            'Taxes (GST)',
                            Formatters.formatCurrency(cart.taxes!),
                          ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total',
                              style: AppTypography.heading2,
                            ),
                            Text(
                              Formatters.formatCurrency(cart.grandTotal),
                              style: AppTypography.price.copyWith(fontSize: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14171A14),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: AppPrimaryButton(
                isLoading: _isProcessing,
                label: _selectedPaymentMethod == PaymentMethodType.cod
                    ? 'Place COD Order (${Formatters.formatCurrency(cart.grandTotal)})'
                    : 'Pay ${Formatters.formatCurrency(cart.grandTotal)} with Razorpay',
                onPressed: _isProcessing ? null : _handleProceedToPay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required PaymentMethodType type,
    required IconData icon,
    String? badgeText,
  }) {
    final bool isSelected = _selectedPaymentMethod == type;

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = type);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.neutral, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.itemName.copyWith(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPressed,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
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
                  child: Text(
                    actionLabel,
                    style: const TextStyle(color: AppColors.primary),
                  ),
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
