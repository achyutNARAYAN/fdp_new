enum AddressType {
  home('Home'),
  work('Work'),
  other('Other');

  final String label;
  const AddressType(this.label);

  static AddressType fromApi(String? apiLabel) {
    switch (apiLabel?.toUpperCase()) {
      case 'HOME':
        return AddressType.home;
      case 'WORK':
        return AddressType.work;
      default:
        return AddressType.other;
    }
  }

  String toApi() {
    switch (this) {
      case AddressType.home:
        return 'HOME';
      case AddressType.work:
        return 'WORK';
      case AddressType.other:
        return 'OTHER';
    }
  }
}

class AddressModel {
  final String id;
  final String title; // e.g. "Flat 402, Lotus Orchid"
  final String fullAddress;
  final String landmark;
  final String pinCode;
  final String city;
  final String state;
  final AddressType type;
  final bool isDefault;
  final bool isServiceable;
  final bool isColdChainEligible;
  final double distanceKm;
  final String contactName;
  final String contactPhone;
  final List<double>? coordinates; // [longitude, latitude]
  final String? deliveryInstructions;

  const AddressModel({
    required this.id,
    required this.title,
    required this.fullAddress,
    required this.landmark,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.type,
    this.isDefault = false,
    this.isServiceable = true,
    this.isColdChainEligible = true,
    this.distanceKm = 2.4,
    required this.contactName,
    required this.contactPhone,
    this.coordinates,
    this.deliveryInstructions,
  });

  AddressModel copyWith({
    String? title,
    String? fullAddress,
    String? landmark,
    String? pinCode,
    String? city,
    String? state,
    AddressType? type,
    bool? isDefault,
    bool? isServiceable,
    bool? isColdChainEligible,
    double? distanceKm,
    String? contactName,
    String? contactPhone,
    List<double>? coordinates,
    String? deliveryInstructions,
  }) {
    return AddressModel(
      id: id,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      landmark: landmark ?? this.landmark,
      pinCode: pinCode ?? this.pinCode,
      city: city ?? this.city,
      state: state ?? this.state,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isServiceable: isServiceable ?? this.isServiceable,
      isColdChainEligible: isColdChainEligible ?? this.isColdChainEligible,
      distanceKm: distanceKm ?? this.distanceKm,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      coordinates: coordinates ?? this.coordinates,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    );
  }

  factory AddressModel.fromApiJson(Map<String, dynamic> json) {
    final house = json['houseNumber']?.toString() ?? '';
    final street = json['streetArea']?.toString() ?? '';
    final lmark = json['landmark']?.toString() ?? '';
    final cty = json['city']?.toString() ?? '';
    final st = json['state']?.toString() ?? 'Karnataka';
    final pin = json['pincode']?.toString() ?? '';

    final full = [house, street, lmark, cty, '$st - $pin']
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    List<double>? coords;
    final loc = json['location'];
    if (loc is Map<String, dynamic> && loc['coordinates'] is List) {
      final list = loc['coordinates'] as List;
      if (list.length >= 2) {
        coords = [
          (list[0] as num).toDouble(),
          (list[1] as num).toDouble(),
        ];
      }
    }

    return AddressModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: house.isNotEmpty ? house : (json['label']?.toString() ?? 'Home'),
      fullAddress: full,
      landmark: lmark,
      pinCode: pin,
      city: cty,
      state: st,
      type: AddressType.fromApi(json['label']?.toString()),
      isDefault: json['isDefault'] ?? false,
      contactName: json['recipientName']?.toString() ?? 'Customer',
      contactPhone: json['recipientPhone']?.toString() ?? '',
      coordinates: coords,
      deliveryInstructions: json['deliveryInstructions']?.toString(),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'label': type.toApi(),
      'recipientName': contactName.isNotEmpty ? contactName : 'Customer',
      'recipientPhone': contactPhone.replaceAll(RegExp(r'[^0-9]'), '').length == 10
          ? contactPhone.replaceAll(RegExp(r'[^0-9]'), '')
          : '9876543210',
      'houseNumber': title.isNotEmpty ? title : 'Flat 402',
      'streetArea': landmark.isNotEmpty ? landmark : 'Main Road',
      'landmark': landmark,
      'city': city.isNotEmpty ? city : 'Bengaluru',
      'state': state.isNotEmpty ? state : 'Karnataka',
      'pincode': pinCode.isNotEmpty ? pinCode : '560038',
      'coordinates': coordinates ?? [77.6412, 12.9716], // Default Indiranagar coordinates within Indian bounds
      'isDefault': isDefault,
      'deliveryInstructions': deliveryInstructions ?? '',
    };
  }
}
