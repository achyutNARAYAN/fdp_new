import 'package:latlong2/latlong.dart';

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
  final String streetArea;
  final String landmark;
  final String pinCode;
  final String city;
  final String state;
  final AddressType type;
  final bool isDefault;
  final bool? isServiceable;
  final bool? isColdChainEligible;
  final double distanceKm;
  final String contactName;
  final String contactPhone;
  final LatLng? coordinates;
  final String? deliveryInstructions;

  const AddressModel({
    required this.id,
    required this.title,
    required this.fullAddress,
    this.streetArea = '',
    required this.landmark,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.type,
    this.isDefault = false,
    this.isServiceable,
    this.isColdChainEligible,
    this.distanceKm = 0,
    required this.contactName,
    required this.contactPhone,
    this.coordinates,
    this.deliveryInstructions,
  });

  AddressModel copyWith({
    String? title,
    String? fullAddress,
    String? streetArea,
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
    LatLng? coordinates,
    String? deliveryInstructions,
  }) {
    return AddressModel(
      id: id,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      streetArea: streetArea ?? this.streetArea,
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
    final st = json['state']?.toString() ?? '';
    final pin = json['pincode']?.toString() ?? '';

    final full = [
      house,
      street,
      lmark,
      cty,
      '$st - $pin',
    ].where((s) => s.trim().isNotEmpty).join(', ');

    LatLng? coords;
    final location = json['location'];
    final rawCoordinates =
        json['coordinates'] ??
        (location is Map<String, dynamic> ? location['coordinates'] : null);
    if (rawCoordinates is List) {
      final list = rawCoordinates;
      if (list.length >= 2) {
        coords = LatLng.fromJson({'coordinates': list});
      }
    }

    return AddressModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: house.isNotEmpty ? house : (json['label']?.toString() ?? ''),
      fullAddress: full,
      streetArea: street,
      landmark: lmark,
      pinCode: pin,
      city: cty,
      state: st,
      type: AddressType.fromApi(json['label']?.toString()),
      isDefault: json['isDefault'] ?? false,
      isServiceable: json['isServiceable'] == true,
      isColdChainEligible: json['isColdChainEligible'] == true,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      contactName: json['recipientName']?.toString() ?? '',
      contactPhone: json['recipientPhone']?.toString() ?? '',
      coordinates: coords,
      deliveryInstructions: json['deliveryInstructions']?.toString(),
    );
  }

  Map<String, dynamic> toApiJson() {
    final phoneDigits = contactPhone.replaceAll(RegExp(r'[^0-9]'), '');
    return {
      'label': type.toApi(),
      'recipientName': contactName,
      'recipientPhone': phoneDigits.length == 12 && phoneDigits.startsWith('91')
          ? phoneDigits.substring(2)
          : phoneDigits,
      'houseNumber': title,
      'streetArea': streetArea.isNotEmpty ? streetArea : landmark,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pinCode,
      if (coordinates != null)
        'coordinates': [coordinates!.longitude, coordinates!.latitude],
      'isDefault': isDefault,
      'deliveryInstructions': deliveryInstructions ?? '',
    };
  }
}
