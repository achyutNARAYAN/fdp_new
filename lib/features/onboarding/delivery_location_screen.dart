import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

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

  Future<void> _useCurrentLocation() async {
    try {
      final placemark = await ref
          .read(locationProvider.notifier)
          .useCurrentLocation();
      if (!mounted) return;
      setState(() {
        _error = null;
        _address = [
          placemark?.name,
          placemark?.subLocality,
          placemark?.locality,
          placemark?.administrativeArea,
          placemark?.postalCode,
        ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
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
          padding: const EdgeInsets.all(AppDimensions.p24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.location_on_outlined,
                size: 56,
                color: AppColors.accent,
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: location.isLoadingLocation
                    ? null
                    : _useCurrentLocation,
                child: const Text('Use current location'),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Continue',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
