enum ShopStatus {
  open('Open Now'),
  busy('Busy • Longer wait'),
  closed('Closed'),
  temporarilyUnavailable('Temporarily Unavailable');

  final String label;
  const ShopStatus(this.label);

  static ShopStatus fromApi(String? apiStatus, bool isAcceptingOrders) {
    if (!isAcceptingOrders) return ShopStatus.closed;
    switch (apiStatus?.toUpperCase()) {
      case 'ACTIVE':
        return ShopStatus.open;
      case 'CLOSED':
        return ShopStatus.closed;
      case 'SUSPENDED':
      case 'DRAFT':
        return ShopStatus.temporarilyUnavailable;
      default:
        return isAcceptingOrders ? ShopStatus.open : ShopStatus.closed;
    }
  }
}

class ShopModel {
  final String id;
  final String storeCode;
  final String name;
  final String tradeName;
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final double distanceKm;
  final String prepTimeMinutes;
  final ShopStatus status;
  final bool isVerified;
  final String fssaiLicense;
  final String gstin;
  final String address;
  final List<String> tags;
  final bool supportsPreOrder;
  final bool isSponsored;
  final bool isAcceptingOrders;
  final List<double>? coordinates; // [longitude, latitude]

  const ShopModel({
    required this.id,
    this.storeCode = '',
    required this.name,
    this.tradeName = '',
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
    required this.distanceKm,
    required this.prepTimeMinutes,
    required this.status,
    required this.isVerified,
    required this.fssaiLicense,
    required this.gstin,
    required this.address,
    required this.tags,
    this.supportsPreOrder = true,
    this.isSponsored = false,
    this.isAcceptingOrders = true,
    this.coordinates,
  });

  bool get isOpen => status == ShopStatus.open && isAcceptingOrders;
  bool get isBusy => status == ShopStatus.busy;
  bool get isClosed => status == ShopStatus.closed || !isAcceptingOrders;

  factory ShopModel.fromApiJson(Map<String, dynamic> json) {
    final addressMap = json['address'] as Map<String, dynamic>?;
    String formattedAddress = '';
    if (addressMap != null) {
      final street = addressMap['street'] ?? '';
      final landmark = addressMap['landmark'] ?? '';
      final city = addressMap['city'] ?? '';
      final pin = addressMap['pinCode'] ?? '';
      formattedAddress = [street, landmark, city, pin]
          .where((s) => s.toString().trim().isNotEmpty)
          .join(', ');
    } else {
      formattedAddress = json['address']?.toString() ?? 'Main Market, City';
    }

    List<double>? coords;
    final locationMap = json['location'] as Map<String, dynamic>?;
    if (locationMap != null && locationMap['coordinates'] is List) {
      final list = locationMap['coordinates'] as List;
      if (list.length >= 2) {
        coords = [
          (list[0] as num).toDouble(),
          (list[1] as num).toDouble(),
        ];
      }
    }

    final bool accepting = json['isAcceptingOrders'] ?? true;
    final String apiStatus = json['status']?.toString() ?? 'ACTIVE';

    return ShopModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      storeCode: json['storeCode']?.toString() ?? '',
      name: json['tradeName']?.toString() ?? json['name']?.toString() ?? 'Confectionery Shop',
      tradeName: json['tradeName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&auto=format&fit=crop&q=80',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      ratingCount: json['ratingCount'] is int ? json['ratingCount'] : 150,
      distanceKm: (json['serviceRadiusKm'] as num?)?.toDouble() ?? 3.2,
      prepTimeMinutes: '15-20 min',
      status: ShopStatus.fromApi(apiStatus, accepting),
      isVerified: json['status'] == 'ACTIVE',
      fssaiLicense: json['fssaiLicence']?.toString() ?? '10019011000123',
      gstin: json['taxProfile']?['gstin']?.toString() ?? '29AAAAA0000A1Z5',
      address: formattedAddress,
      tags: [
        json['category']?.toString().replaceAll('_', ' ').toLowerCase() ?? 'sweets',
        'FSSAI Certified',
        'Artisanal',
      ],
      isAcceptingOrders: accepting,
      coordinates: coords,
    );
  }
}
