import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import 'package:fdp/features/orders/providers/order_provider.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/buttons/app_secondary_button.dart';
import 'package:fdp/core/widgets/layout/no_order_data.dart';

class GstInvoiceScreen extends ConsumerWidget {
  final String orderId;

  const GstInvoiceScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final order =
        orderState.pastOrders.where((o) => o.orderId == orderId).firstOrNull ??
        (orderState.activeOrder?.orderId == orderId
            ? orderState.activeOrder
            : null);
    if (order == null) return const NoOrderData();

    final double taxableItems = order.subtotal - order.discountAmount;
    final double cgst = order.taxes / 2;
    final double sgst = order.taxes / 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tax Invoice (Form GST INV-1)'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppDimensions.elevationLevel2,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thin 8px Sage Green header band (Section 24 visual spec)
                    Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.p20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Confectioner & Tax Invoice Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.shopName,
                                    style: AppTypography.heading2,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.shopAddress,
                                    style: AppTypography.caption,
                                  ),
                                  Text(
                                    'FSSAI Lic. No: ${order.fssaiLicense}',
                                    style: AppTypography.caption,
                                  ),
                                  Text(
                                    'GSTIN: ${order.gstin}',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTint20,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TAX INVOICE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 24),

                          // Invoice Number, Date, Customer Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Billed To (Customer):',
                                    style: AppTypography.caption,
                                  ),
                                  const Text(
                                    'Aarav Sharma',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      order.deliveryAddress,
                                      style: AppTypography.caption,
                                    ),
                                  ),
                                  const Text(
                                    'State: Karnataka (29)',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Invoice #: INV-${order.orderId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Date: ${Formatters.formatDate(order.createdAt)}',
                                    style: AppTypography.caption,
                                  ),
                                  Text(
                                    'Order ID: #${order.orderId}',
                                    style: AppTypography.caption,
                                  ),
                                  Text(
                                    'Payment: ${order.paymentStatus.label}',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Table Ruled in Concrete Grey 25%
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: AppColors.primaryTint10,
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          'Item / HSN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Qty / Wt',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rate',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Total',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...order.items.map((cartItem) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: AppColors.divider,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cartItem.item.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${cartItem.quantity} (${cartItem.selectedVariant.label})',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            Formatters.formatCurrency(
                                              cartItem.selectedVariant.price,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            Formatters.formatCurrency(
                                              cartItem.totalPrice,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tax Computation Summary (CGST & SGST)
                          _invRow(
                            'Taxable Value of Food Items',
                            Formatters.formatCurrency(taxableItems),
                          ),
                          _invRow(
                            'Central GST',
                            Formatters.formatCurrency(cgst),
                          ),
                          _invRow('State GST', Formatters.formatCurrency(sgst)),
                          _invRow(
                            'Delivery Partner Logistics Fee',
                            Formatters.formatCurrency(order.deliveryFee),
                          ),
                          _invRow(
                            'Insulated Cold Packaging Charge',
                            Formatters.formatCurrency(order.packagingFee),
                          ),
                          _invRow(
                            'Platform Convenience Fee',
                            Formatters.formatCurrency(order.platformFee),
                          ),
                          if (order.tipAmount > 0)
                            _invRow(
                              'Delivery Tip (Untaxed Grant)',
                              Formatters.formatCurrency(order.tipAmount),
                            ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Invoice Amount (INR)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(order.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const Center(
                            child: Text(
                              'This is a digitally generated GST Tax Invoice under Section 31 of CGST Act, 2017. No signature required.',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bar: Download & Share
          Container(
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
            child: Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Share PDF',
                    icon: Icons.share_outlined,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice link copied to clipboard.'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Download Invoice',
                    icon: Icons.download_outlined,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'GST Invoice downloaded to your device.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
