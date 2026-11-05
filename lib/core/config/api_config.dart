import 'env_config.dart';

class ApiConfig {
  ApiConfig._();

  /// Primary API Base URL
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return EnvConfig.get(
      'API_BASE_URL',
      defaultValue: 'https://fdp-tkl0.onrender.com/api/v1',
    );
  }

  /// Root Server URL (for /health and /health/ready probes)
  static String get rootUrl {
    const fromDefine = String.fromEnvironment('API_ROOT_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return EnvConfig.get(
      'API_ROOT_URL',
      defaultValue: 'https://fdp-tkl0.onrender.com',
    );
  }

  /// Live WebSocket Gateway URL
  static String get wsUrl {
    const fromDefine = String.fromEnvironment('WS_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    final envVal = EnvConfig.get('WS_URL');
    if (envVal.isNotEmpty) return envVal;
    final root = rootUrl;
    if (root.startsWith('https://')) {
      return '${root.replaceFirst('https://', 'wss://')}/ws';
    } else if (root.startsWith('http://')) {
      return '${root.replaceFirst('http://', 'ws://')}/ws';
    }
    return 'wss://fdp-tkl0.onrender.com/ws';
  }

  /// Network Timeout
  static Duration get timeout {
    final timeoutSec = EnvConfig.get('API_TIMEOUT_SECONDS');
    final seconds = int.tryParse(timeoutSec) ?? 45;
    return Duration(seconds: seconds);
  }

  /// Google OAuth Web Client ID (from Google Cloud Console via .env)
  static String get googleServerClientId {
    const fromDefine = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return EnvConfig.get('GOOGLE_SERVER_CLIENT_ID');
  }

  /// Razorpay Payment Gateway Key ID (Public Key ID only via .env)
  static String get razorpayKeyId {
    const fromDefine = String.fromEnvironment('RAZORPAY_KEY_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return EnvConfig.get('RAZORPAY_KEY_ID');
  }

  /// Enable full API request/response logging in terminal
  static bool get enableLogging {
    const fromDefine = bool.fromEnvironment('ENABLE_LOGGING');
    if (fromDefine) return true;
    final envVal = EnvConfig.get('ENABLE_LOGGING');
    if (envVal.isNotEmpty) return envVal.toLowerCase() == 'true';
    return false;
  }

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
