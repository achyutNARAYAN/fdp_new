import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/models/address_model.dart';
import '../../shared/providers/address_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? existingAddress;

  const AddEditAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  late TextEditingController _flatController;
  late TextEditingController _streetController;
  late TextEditingController _landmarkController;
  late TextEditingController _pinController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _instructionsController;
  LatLng? _coordinates;
  AddressType _addressType = AddressType.home;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    final user = ref.read(authProvider).user;
    _coordinates =
        addr?.coordinates ?? ref.read(locationProvider).currentCoordinates;
    _flatController = TextEditingController(text: addr?.title ?? '');
    _streetController = TextEditingController(text: addr?.streetArea ?? '');
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _pinController = TextEditingController(text: addr?.pinCode ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _nameController = TextEditingController(
      text: addr?.contactName ?? user?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: addr?.contactPhone ?? user?.mobileNumber ?? '',
    );
    _instructionsController = TextEditingController();
    _addressType = addr?.type ?? AddressType.home;
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _flatController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _pinController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = phoneDigits.length == 12 && phoneDigits.startsWith('91')
        ? phoneDigits.substring(2)
        : phoneDigits;
    if (_flatController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty ||
        _pinController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        phone.length != 10 ||
        _coordinates == null ||
        !_coordinates!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete the address and contact details, then pin your current location.',
          ),
        ),
      );
      return;
    }

    final newAddr = AddressModel(
      id:
          widget.existingAddress?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      title: _flatController.text.trim(),
      fullAddress:
          '${_flatController.text.trim()}, ${_streetController.text.trim()}, ${_cityController.text.trim()} - ${_pinController.text.trim()}',
      streetArea: _streetController.text.trim(),
      landmark: _landmarkController.text.trim(),
      pinCode: _pinController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      type: _addressType,
      isDefault: _isDefault,
      contactName: _nameController.text.trim(),
      contactPhone: phone,
      coordinates: _coordinates,
    );

    try {
      if (widget.existingAddress != null) {
        await ref.read(addressListProvider.notifier).editAddress(newAddr);
      } else {
        await ref.read(addressListProvider.notifier).addAddress(newAddr);
      }
      if (!mounted) return;
      ref.read(locationProvider.notifier).selectAddress(newAddr);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save address: $e')));
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final placemark = await ref
          .read(locationProvider.notifier)
          .useCurrentLocation();
      if (!mounted) return;
      setState(() {
        _coordinates = ref.read(locationProvider).currentCoordinates;
        if (placemark != null) {
          _setIfAvailable(_flatController, placemark.subThoroughfare);
          _setIfAvailable(
            _streetController,
            _firstAvailable([
              placemark.thoroughfare,
              placemark.subLocality,
              placemark.subAdministrativeArea,
            ]),
          );
          _setIfAvailable(
            _landmarkController,
            placemark.name == placemark.thoroughfare ? null : placemark.name,
          );
          _setIfAvailable(
            _cityController,
            _firstAvailable([
              placemark.locality,
              placemark.subAdministrativeArea,
            ]),
          );
          _setIfAvailable(_stateController, placemark.administrativeArea);
          _setIfAvailable(_pinController, placemark.postalCode);
        }
      });
      if (placemark == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location pinned. Address details were unavailable, so please enter them manually.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  String? _firstAvailable(List<String?> values) => values
      .whereType<String>()
      .map((value) => value.trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');

  void _setIfAvailable(TextEditingController controller, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      controller.text = value.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingAddress != null ? 'Edit Address' : 'Add New Address',
        ),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Collapsed 30% map pin preview
                  Container(
                    height: 140,
                    color: const Color(0xFFE8ECE9),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 36,
                          color: AppColors.accent,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Set delivery location using your phone GPS',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Fields
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address Type Selector (Home, Work, Other)
                        const Text(
                          'Save Address As',
                          style: AppTypography.itemName,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: AddressType.values.map((type) {
                            final isSelected = _addressType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _addressType = type),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryTint20
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.neutralBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    type.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        AppTextField(
                          controller: _flatController,
                          label: 'House / Flat / Block No. *',
                          hint: 'e.g. Flat 402, Lotus Orchid Apartments',
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _stateController,
                          label: 'State *',
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _streetController,
                          label: 'Street / Area / Colony *',
                          hint: 'e.g. 8th Main Road, Gandhi Nagar',
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _landmarkController,
                          label: 'Landmark (Optional)',
                          hint: 'e.g. Near BDA Complex, 8th Main',
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _pinController,
                                label: 'PIN Code *',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _cityController,
                                label: 'City *',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _nameController,
                          label: 'Recipient Name *',
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _phoneController,
                          label: 'Contact Number *',
                          keyboardType: TextInputType.phone,
                          hint: '10-digit Indian mobile number',
                        ),
                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed:
                              ref.watch(locationProvider).isLoadingLocation
                              ? null
                              : _useCurrentLocation,
                          icon: ref.watch(locationProvider).isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            _coordinates == null
                                ? 'Use my current location'
                                : 'Location pinned',
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: _instructionsController,
                          label: 'Delivery Instructions (Optional)',
                          hint: 'e.g. Leave with security / Ring bell twice',
                        ),
                        const SizedBox(height: 16),

                        // Default checkbox
                        CheckboxListTile(
                          value: _isDefault,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          title: const Text(
                            'Set as default delivery address',
                            style: AppTypography.bodySmall,
                          ),
                          onChanged: (val) =>
                              setState(() => _isDefault = val ?? false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Save Address CTA
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14171A14),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: AppPrimaryButton(
                label: 'Save Address',
                onPressed: _saveAddress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
