import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'package:fdp/core/models/address_model.dart';
import 'package:fdp/features/auth/providers/auth_provider.dart';
import 'package:fdp/core/providers/location_provider.dart';
import 'package:fdp/core/widgets/buttons/app_primary_button.dart';
import 'package:fdp/core/widgets/location_map.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 340;
            if (isCompactHeight) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LocationMap(
                      center:
                          location.currentCoordinates ??
                          location.selectedAddress?.coordinates,
                      height: 160,
                      onTap: _selectLocation,
                    ),
                    const SizedBox(height: 10),
                    _buildAddressCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      _buildError(),
                    ],
                    const SizedBox(height: 8),
                    _buildCurrentLocationButton(location),
                    const SizedBox(height: 8),
                    _buildContinueButton(location),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LocationMap(
                      center:
                          location.currentCoordinates ??
                          location.selectedAddress?.coordinates,
                      height: null,
                      onTap: _selectLocation,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAddressCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    _buildError(),
                  ],
                  const SizedBox(height: 8),
                  _buildCurrentLocationButton(location),
                  const SizedBox(height: 8),
                  _buildContinueButton(location),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _address.isEmpty ? 'Tap map or use current location' : _address,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Text(
      _error!,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.accent,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCurrentLocationButton(LocationState location) {
    return OutlinedButton.icon(
      onPressed: location.isLoadingLocation ? null : _useCurrentLocation,
      icon: location.isLoadingLocation
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location, size: 18),
      label: const Text('Use current location'),
    );
  }

  Widget _buildContinueButton(LocationState location) {
    return AppPrimaryButton(
      label: 'Continue',
      onPressed: location.currentCoordinates == null
          ? null
          : _continueWithAddress,
      isLoading: _isSaving,
    );
  }
}
