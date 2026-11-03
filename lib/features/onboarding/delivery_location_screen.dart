import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/address_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';
import '../../shared/widgets/location_map.dart';

class DeliveryLocationScreen extends ConsumerStatefulWidget {
  const DeliveryLocationScreen({super.key});

  @override
  ConsumerState<DeliveryLocationScreen> createState() =>
      _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState
    extends ConsumerState<DeliveryLocationScreen> {
  String _address = '';
  String? _error;
  bool _isSaving = false;

  Future<void> _useCurrentLocation() async {
    try {
      final placemark = await ref
          .read(locationProvider.notifier)
          .useCurrentLocation();
      if (!mounted) return;
      setState(() {
        _error = null;
        _address = placemark?.displayName ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _selectLocation(LatLng point) async {
    ref.read(locationProvider.notifier).selectCoordinates(point);
    setState(() {
      _address = 'Pinned location';
      _error = null;
    });
    try {
      final address = await GeocodingService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted && address != null) {
        setState(() => _address = address.displayName);
      }
    } catch (_) {
      // The coordinate is still pinned if reverse geocoding is unavailable.
    }
  }

  Future<void> _continueWithAddress() async {
    final coordinates = ref.read(locationProvider).currentCoordinates;
    final user = ref.read(authProvider).user;
    if (coordinates == null || user == null) return;

    setState(() => _isSaving = true);
    try {
      final address = AddressModel(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        title: _address.isEmpty ? 'Pinned address' : _address,
        fullAddress: _address,
        landmark: '',
        pinCode: '',
        city: '',
        state: '',
        type: AddressType.home,
        isDefault: true,
        contactName: user.fullName,
        contactPhone: user.mobileNumber ?? '',
        coordinates: coordinates,
      );
      final saved = await context.push<bool>('/add-address', extra: address);
      if (!mounted) return;
      if (saved == true) context.go('/home');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Set Delivery Location')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.p16),
          child: Column(
            children: [
              LocationMap(
                center:
                    location.currentCoordinates ??
                    location.selectedAddress?.coordinates,
                height: 380,
                onTap: _selectLocation,
              ),
              const SizedBox(height: 16),
              Text(
                _address.isEmpty ? 'No location selected' : _address,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: location.isLoadingLocation
                    ? null
                    : _useCurrentLocation,
                child: location.isLoadingLocation
                    ? const CircularProgressIndicator()
                    : const Text('Use current location'),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Continue',
                onPressed: location.currentCoordinates == null
                    ? null
                    : _continueWithAddress,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
