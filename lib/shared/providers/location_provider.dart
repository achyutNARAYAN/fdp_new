import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';
import '../data/mock_data.dart';

class LocationState {
  final AddressModel selectedAddress;
  final bool isPermissionGranted;
  final bool isGpsEnabled;
  final bool isLoadingLocation;

  const LocationState({
    required this.selectedAddress,
    this.isPermissionGranted = true,
    this.isGpsEnabled = true,
    this.isLoadingLocation = false,
  });

  LocationState copyWith({
    AddressModel? selectedAddress,
    bool? isPermissionGranted,
    bool? isGpsEnabled,
    bool? isLoadingLocation,
  }) {
    return LocationState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
      : super(LocationState(
          selectedAddress: MockData.savedAddresses.first,
        ));

  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  void updatePinCode(String pinCode) {
    // Check serviceability
    final isServiceable = pinCode.startsWith('560'); // Bangalore test rule
    final updated = state.selectedAddress.copyWith(
      pinCode: pinCode,
      isServiceable: isServiceable,
      isColdChainEligible: isServiceable && !pinCode.endsWith('99'),
    );
    state = state.copyWith(selectedAddress: updated);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

