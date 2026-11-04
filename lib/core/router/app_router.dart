import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/onboarding/profile_completion_screen.dart';
import '../../features/onboarding/delivery_location_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/search/search_results_screen.dart';
import '../../features/home/category_screen.dart';
import '../../features/shop/shop_page_screen.dart';
import '../../features/item/item_details_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/delivery_time_screen.dart';
import '../../features/checkout/address_selection_screen.dart';
import '../../features/checkout/add_edit_address_screen.dart';
import '../../features/checkout/offers_coupons_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/payment/payment_method_screen.dart';
import '../../features/payment/payment_processing_screen.dart';
import '../../features/payment/payment_result_screen.dart';
import '../../features/order_confirmation/order_request_submitted_screen.dart';
import '../../features/order_confirmation/waiting_confirmation_screen.dart';
import '../../features/order_confirmation/order_confirmed_screen.dart';
import '../../features/order_confirmation/shop_proposed_changes_screen.dart';
import '../../features/order_confirmation/shop_declined_order_screen.dart';
import '../../features/order_confirmation/cod_order_placement_screen.dart';
import '../../features/order_confirmation/confirmation_timeout_screen.dart';
import '../../features/order_tracking/order_tracking_screen.dart';
import '../../features/delivery/live_delivery_map_screen.dart';
import '../../features/delivery/delivery_issue_screen.dart';
import '../../features/delivery/order_delivered_screen.dart';
import '../../features/delivery/rate_review_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/order_details_screen.dart';
import '../../features/orders/gst_invoice_screen.dart';
import '../../features/orders/cancel_order_screen.dart';
import '../../features/orders/refund_status_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/saved_addresses_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/support/support_center_screen.dart';
import '../../features/support/raise_ticket_screen.dart';
import '../../features/support/ticket_details_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'package:fdp/core/widgets/layout/main_scaffold.dart';
import 'package:fdp/core/models/address_model.dart';
import 'package:fdp/features/item/models/item_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Screen 1: Splash
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    // Screen 2: Login
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // Screen 3: OTP Verification
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) => const OtpVerificationScreen(),
    ),

    // Screen 4: Profile Completion
    GoRoute(
      path: '/profile-completion',
      builder: (context, state) => const ProfileCompletionScreen(),
    ),

    // Screen 5: Delivery Location
    GoRoute(
      path: '/delivery-location',
      builder: (context, state) => const DeliveryLocationScreen(),
    ),

    // Shell Route with MainScaffold for Bottom Navigation Tabs
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        int index = 0;
        final location = state.uri.toString();
        if (location.startsWith('/search')) {
          index = 1;
        } else if (location.startsWith('/orders')) {
          index = 2;
        } else if (location.startsWith('/favorites')) {
          index = 3;
        } else if (location.startsWith('/profile')) {
          index = 4;
        }
        return MainScaffold(currentIndex: index, child: child);
      },
      routes: [
        // Screen 6: Home
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

        // Screen 7: Search
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),

        // Screen 36: Orders
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrderHistoryScreen(),
        ),

        // Screen 13: Favorites & Reorder Hub
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),

        // Screen 41: Profile
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Screen 8: Search Results
    GoRoute(
      path: '/search-results',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        return SearchResultsScreen(query: query);
      },
    ),

    // Screen 9: Category
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? 'Sweets';
        return CategoryScreen(categoryName: name);
      },
    ),

    // Screen 10: Shop Page
    GoRoute(
      path: '/shop/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ShopPageScreen(shopId: id);
      },
    ),

    // Screen 11: Item Details
    GoRoute(
      path: '/item/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ItemDetailsScreen(
          itemId: id,
          initialItem: state.extra as ItemModel?,
        );
      },
    ),

    // Screen 14: Cart
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),

    // Screen 15: Delivery Time
    GoRoute(
      path: '/delivery-time',
      builder: (context, state) => const DeliveryTimeScreen(),
    ),

    // Screen 16: Address Selection
    GoRoute(
      path: '/address-selection',
      builder: (context, state) => const AddressSelectionScreen(),
    ),

    // Screen 17: Add / Edit Address
    GoRoute(
      path: '/add-address',
      builder: (context, state) =>
          AddEditAddressScreen(initialAddress: state.extra as AddressModel?),
    ),

    // Screen 18: Offers & Coupons
    GoRoute(
      path: '/offers',
      builder: (context, state) => const OffersCouponsScreen(),
    ),

    // Screen 19: Checkout
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),

    // Screen 20: Payment Method
    GoRoute(
      path: '/payment-method',
      builder: (context, state) => const PaymentMethodScreen(),
    ),

    // Screen 21: Payment Processing
    GoRoute(
      path: '/payment-processing',
      builder: (context, state) {
        final method = state.uri.queryParameters['method'] ?? 'upi';
        return PaymentProcessingScreen(method: method);
      },
    ),

    // Screen 22: Payment Result
    GoRoute(
      path: '/payment-result',
      builder: (context, state) {
        final status = state.uri.queryParameters['status'] ?? '';
        return PaymentResultScreen(status: status);
      },
    ),

    // Screen 23: Order Request Submitted
    GoRoute(
      path: '/order-request-submitted/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderRequestSubmittedScreen(orderId: orderId);
      },
    ),

    // Screen 24: Waiting for Shop Confirmation (3 min)
    GoRoute(
      path: '/waiting-confirmation/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return WaitingConfirmationScreen(orderId: orderId);
      },
    ),

    // Screen 26: Order Confirmed
    GoRoute(
      path: '/order-confirmed/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderConfirmedScreen(orderId: orderId);
      },
    ),

    // Screen 27: Shop Proposed Changes
    GoRoute(
      path: '/shop-proposed-changes/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return ShopProposedChangesScreen(orderId: orderId);
      },
    ),

    // Screen 28: Shop Declined Order
    GoRoute(
      path: '/shop-declined-order/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return ShopDeclinedOrderScreen(orderId: orderId);
      },
    ),

    // Screen 29: COD Order Placement
    GoRoute(
      path: '/cod-placement',
      builder: (context, state) => const CodOrderPlacementScreen(),
    ),

    // Screen 30: Confirmation Timeout
    GoRoute(
      path: '/confirmation-timeout/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return ConfirmationTimeoutScreen(orderId: orderId);
      },
    ),

    // Screen 31: Order Tracking Timeline
    GoRoute(
      path: '/order-tracking/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderTrackingScreen(orderId: orderId);
      },
    ),

    // Screen 32: Live Delivery Map & Partner
    GoRoute(
      path: '/live-map/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return LiveDeliveryMapScreen(orderId: orderId);
      },
    ),

    // Screen 33: Delivery Issue
    GoRoute(
      path: '/delivery-issue/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return DeliveryIssueScreen(orderId: orderId);
      },
    ),

    // Screen 34: Order Delivered
    GoRoute(
      path: '/order-delivered/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderDeliveredScreen(orderId: orderId);
      },
    ),

    // Screen 35: Rate & Review
    GoRoute(
      path: '/rate-review/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return RateReviewScreen(orderId: orderId);
      },
    ),

    // Screen 37: Order Details
    GoRoute(
      path: '/order-details/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return OrderDetailsScreen(orderId: orderId);
      },
    ),

    // Screen 38: GST Tax Invoice
    GoRoute(
      path: '/invoice/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return GstInvoiceScreen(orderId: orderId);
      },
    ),

    // Screen 39: Cancel Order
    GoRoute(
      path: '/cancel-order/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return CancelOrderScreen(orderId: orderId);
      },
    ),

    // Screen 40: Refund Status
    GoRoute(
      path: '/refund-status/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        return RefundStatusScreen(orderId: orderId);
      },
    ),

    // Screen 42: Edit Profile
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),

    // Screen 43: Saved Addresses
    GoRoute(
      path: '/saved-addresses',
      builder: (context, state) => const SavedAddressesScreen(),
    ),

    // Screen 44: Notifications
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Screen 45: Support Center
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportCenterScreen(),
    ),

    // Screen 46: Raise Ticket
    GoRoute(
      path: '/raise-ticket',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        return RaiseTicketScreen(initialOrderId: orderId);
      },
    ),

    // Screen 47: Ticket Details
    GoRoute(
      path: '/ticket-details/:ticketId',
      builder: (context, state) {
        final ticketId = state.pathParameters['ticketId'] ?? '';
        return TicketDetailsScreen(ticketId: ticketId);
      },
    ),

    // Screen 48: Settings
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
