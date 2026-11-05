enum ShopStatus {
  unknown(''),
  open('Open Now'),
  busy('Busy • Longer wait'),
  closed('Closed'),
  temporarilyUnavailable('Temporarily Unavailable');

  final String label;
  const ShopStatus(this.label);

  static ShopStatus fromApi(
    String? apiStatus,
    bool isAcceptingOrders, {
    bool? isOpen,
  }) {
    if (isOpen == false) return ShopStatus.closed;
    if (isOpen == true && isAcceptingOrders) return ShopStatus.open;
    if (apiStatus == null || apiStatus.isEmpty) {
      return isAcceptingOrders ? ShopStatus.open : ShopStatus.closed;
    }
    if (!isAcceptingOrders) return ShopStatus.closed;
    switch (apiStatus.toUpperCase()) {
      case 'ACTIVE':
        return ShopStatus.open;
      case 'CLOSED':
        return ShopStatus.closed;
      case 'SUSPENDED':
      case 'DRAFT':
        return ShopStatus.temporarilyUnavailable;
      default:
        return ShopStatus.unknown;
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
  final String distanceTier; // TIER_1, TIER_2, TIER_3
  final int deliveryFeePaise;

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
    this.supportsPreOrder = false,
    this.isSponsored = false,
    this.isAcceptingOrders = false,
    this.coordinates,
    this.distanceTier = '',
    this.deliveryFeePaise = 0,
  });

  bool get isOpen => status == ShopStatus.open && isAcceptingOrders;
  bool get isBusy => status == ShopStatus.busy;
  bool get isClosed =>
      status == ShopStatus.closed ||
      (status != ShopStatus.unknown && !isAcceptingOrders);
  double get deliveryFeeRupees => deliveryFeePaise / 100.0;

  factory ShopModel.fromApiJson(Map<String, dynamic> json) {
    final addressMap = json['address'] as Map<String, dynamic>?;
    String formattedAddress = '';
    if (addressMap != null) {
      final street = addressMap['street'] ?? addressMap['streetArea'] ?? '';
      final landmark = addressMap['landmark'] ?? '';
      final city = addressMap['city'] ?? '';
      final pin = addressMap['pinCode'] ?? addressMap['pincode'] ?? '';
      formattedAddress = [
        street,
        landmark,
        city,
        pin,
      ].where((s) => s.toString().trim().isNotEmpty).join(', ');
    } else {
      formattedAddress = json['address']?.toString() ?? '';
    }

    List<double>? coords;
    final locationMap = json['location'] as Map<String, dynamic>?;
    if (locationMap != null && locationMap['coordinates'] is List) {
      final list = locationMap['coordinates'] as List;
      if (list.length >= 2) {
        coords = [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
      }
    } else if (json['coordinates'] is List) {
      final list = json['coordinates'] as List;
      if (list.length >= 2) {
        coords = [(list[0] as num).toDouble(), (list[1] as num).toDouble()];
      }
    }

    final String? apiStatus = json['status']?.toString();
    final bool? explicitIsOpen = json['isOpen'] is bool
        ? json['isOpen'] as bool
        : null;
    final bool accepting = json['isAcceptingOrders'] is bool
        ? json['isAcceptingOrders'] as bool
        : (explicitIsOpen ?? (apiStatus?.toUpperCase() == 'ACTIVE'));

    final int reviews = json['reviewCount'] is num
        ? (json['reviewCount'] as num).toInt()
        : (json['ratingCount'] is num
            ? (json['ratingCount'] as num).toInt()
            : 0);

    final String prep = json['estimatedDeliveryMinutes'] != null
        ? '${json['estimatedDeliveryMinutes']} mins'
        : (json['prepTimeMinutes']?.toString() ?? '');

    final String img = (json['bannerUrl'] != null &&
            json['bannerUrl'].toString().isNotEmpty)
        ? json['bannerUrl'].toString()
        : (json['imageUrl']?.toString() ?? '');

    return ShopModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      storeCode: json['storeCode']?.toString() ?? '',
      name: json['name']?.toString() ?? json['tradeName']?.toString() ?? '',
      tradeName: json['tradeName']?.toString() ?? '',
      imageUrl: img,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: reviews,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      prepTimeMinutes: prep,
      status: ShopStatus.fromApi(apiStatus, accepting, isOpen: explicitIsOpen),
      isVerified: json['status'] == 'ACTIVE' || explicitIsOpen == true,
      fssaiLicense: json['fssaiLicence']?.toString() ?? '',
      gstin: json['taxProfile']?['gstin']?.toString() ?? '',
      address: formattedAddress,
      tags: [
        if (json['category'] != null)
          json['category'].toString().replaceAll('_', ' ').toLowerCase(),
      ],
      isAcceptingOrders: accepting,
      supportsPreOrder: json['supportsPreOrder'] == true,
      isSponsored: json['isSponsored'] == true,
      coordinates: coords,
      distanceTier: json['distanceTier']?.toString() ?? '',
      deliveryFeePaise: (json['deliveryFeePaise'] as num?)?.toInt() ?? 0,
    );
  }
}
