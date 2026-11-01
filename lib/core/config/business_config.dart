/// Business-configurable rules as mandated by Section 0 & 4:
/// "Cancellation windows, refund timings, perishable-return policy, COD limits and fees
/// are business-configurable. The UI must read them from configuration and never hard-code them."
class BusinessConfig {
  final String appName;
  final String tagline;
  final String currencySymbol;
  final int shopConfirmationSeconds; // 180s (03:00)
  final double minimumOrderValue;
  final double platformFee;
  final double defaultPackagingFee;
  final double defaultDeliveryFee;
  final double maxCodLimit;
  final double coldChainMaxRadiusKm;
  final int maxCakeMessageChars;
  final Duration perishableIssueReportingWindow;
  final Duration standardIssueReportingWindow;

  const BusinessConfig({
    this.appName = 'Mithai & More',
    this.tagline = 'Sweet moments, delivered with care.',
    this.currencySymbol = '₹',
    this.shopConfirmationSeconds = 180,
    this.minimumOrderValue = 199.0,
    this.platformFee = 5.0,
    this.defaultPackagingFee = 15.0,
    this.defaultDeliveryFee = 35.0,
    this.maxCodLimit = 2000.0,
    this.coldChainMaxRadiusKm = 6.0,
    this.maxCakeMessageChars = 30,
    this.perishableIssueReportingWindow = const Duration(hours: 2),
    this.standardIssueReportingWindow = const Duration(hours: 12),
  });

  static const BusinessConfig defaultConfig = BusinessConfig();
}

