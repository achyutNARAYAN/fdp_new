import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/address_model.dart';

class LocationState {
  final AddressModel? selectedAddress;
  final LatLng? currentCoordinates;
  final bool isPermissionGranted;
  final bool isGpsEnabled;
  final bool isLoadingLocation;

  const LocationState({
    this.selectedAddress,
    this.currentCoordinates,
    this.isPermissionGranted = true,
    this.isGpsEnabled = true,
    this.isLoadingLocation = false,
  });

  LocationState copyWith({
    AddressModel? selectedAddress,
    LatLng? currentCoordinates,
    bool? isPermissionGranted,
    bool? isGpsEnabled,
    bool? isLoadingLocation,
  }) {
    return LocationState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      currentCoordinates: currentCoordinates ?? this.currentCoordinates,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  void selectAddress(AddressModel address) {
    state = state.copyWith(
      selectedAddress: address,
      currentCoordinates: address.coordinates,
    );
  }

  Future<Placemark?> useCurrentLocation() async {
    state = state.copyWith(isLoadingLocation: true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services and try again.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Allow location access to pin your delivery address.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final coordinates = LatLng(position.latitude, position.longitude);
      state = state.copyWith(
        currentCoordinates: coordinates,
        selectedAddress: state.selectedAddress?.copyWith(
          coordinates: coordinates,
        ),
      );
      final List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } on MissingPluginException {
        rethrow;
      } on PlatformException {
        return null;
      }
      return placemarks.isEmpty ? null : placemarks.first;
    } on MissingPluginException {
      throw StateError(
        'Location support needs a full app restart. Stop the app and run it again.',
      );
    } finally {
      state = state.copyWith(isLoadingLocation: false);
    }
  }

  void updatePinCode(String pinCode) {
    // Check serviceability
    // Serviceability must come from the API.
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);
