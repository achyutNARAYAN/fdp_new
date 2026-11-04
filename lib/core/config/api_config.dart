class ApiConfig {
  ApiConfig._();

  /// Primary Production API Base URL (Render cloud)
  static const String baseUrl = 'https://fdp-tkl0.onrender.com/api/v1';

  /// Root Server URL (for /health and /health/ready probes)
  static const String rootUrl = 'https://fdp-tkl0.onrender.com';

  /// Network Timeout (Render cold starts can take up to 45s)
  static const Duration timeout = Duration(seconds: 45);

  /// Google OAuth Web Client ID (from Google Cloud Console)
  /// If provided, Android Google Play Services returns an OpenID idToken for the backend
  static const String googleServerClientId =
      '251374570662-1doulus75vv493d0o572e8vkndjdbtc0.apps.googleusercontent.com';

  /// Razorpay Payment Gateway Key (Public Key ID only - Secret Key must NEVER be on frontend)
  static const String razorpayKeyId = 'rzp_test_Tvfe16OIBHNqTe';

  /// Enable full API request/response logging in terminal
  static bool enableLogging = true;

  /// Convert paise (integer) to Rupees (double)
  /// e.g. 90000 paise -> ₹900.00
  static double paiseToRupees(dynamic paise) {
    if (paise == null) return 0.0;
    if (paise is num) return (paise / 100.0);
    final parsed = double.tryParse(paise.toString());
    return (parsed != null) ? (parsed / 100.0) : 0.0;
  }

  /// Convert Rupees (double) to paise (integer)
  /// e.g. ₹450.50 -> 45050 paise
  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }

  /// Format standard measurement units for Indian sweets & desserts
  static String formatMeasurementUnit(String unit) {
    switch (unit.toUpperCase()) {
      case 'KG':
        return '1 kg';
      case 'HALF_KG':
        return '500 g';
      case 'QUARTER_KG':
        return '250 g';
      case 'PIECE':
        return '1 pc';
      case 'BOX':
        return '1 box';
      case 'PLATE':
        return '1 plate';
      case 'PORTION':
        return '1 portion';
      case 'PACKET':
        return '1 packet';
      case 'SCOOP':
        return '1 scoop';
      case 'TUB':
        return '1 tub (500ml)';
      case 'LITRE':
        return '1 L';
      case 'ML':
        return '100 ml';
      default:
        return unit;
    }
  }
}
