import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/models/address_model.dart';
import '../../shared/providers/address_provider.dart';
import '../../shared/providers/location_provider.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? existingAddress;

  const AddEditAddressScreen({
    super.key,
    this.existingAddress,
  });

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  late TextEditingController _flatController;
  late TextEditingController _landmarkController;
  late TextEditingController _pinController;
  late TextEditingController _cityController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _instructionsController;
  AddressType _addressType = AddressType.home;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _flatController = TextEditingController(text: addr?.title ?? '');
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _pinController = TextEditingController(text: addr?.pinCode ?? '560038');
    _cityController = TextEditingController(text: addr?.city ?? 'Bengaluru');
    _nameController = TextEditingController(text: addr?.contactName ?? 'Aarav Sharma');
    _phoneController = TextEditingController(text: addr?.contactPhone ?? '+91 98765 43210');
    _instructionsController = TextEditingController();
    _addressType = addr?.type ?? AddressType.home;
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _flatController.dispose();
    _landmarkController.dispose();
    _pinController.dispose();
    _cityController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_flatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter flat/house number and street.')),
      );
      return;
    }

    final newAddr = AddressModel(
      id: widget.existingAddress?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
      title: _addressType.label,
      fullAddress: '${_flatController.text.trim()}, ${_landmarkController.text.trim()}, ${_cityController.text.trim()} - ${_pinController.text.trim()}',
      landmark: _landmarkController.text.trim(),
      pinCode: _pinController.text.trim(),
      city: _cityController.text.trim(),
      state: 'Karnataka',
      type: _addressType,
      isDefault: _isDefault,
      contactName: _nameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
    );

    if (widget.existingAddress != null) {
      ref.read(addressListProvider.notifier).editAddress(newAddr);
    } else {
      ref.read(addressListProvider.notifier).addAddress(newAddr);
    }

    ref.read(locationProvider.notifier).selectAddress(newAddr);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingAddress != null ? 'Edit Address' : 'Add New Address'),
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
                        Icon(Icons.location_on, size: 36, color: AppColors.accent),
                        SizedBox(height: 4),
                        Text('Indiranagar, Bengaluru 560038', style: AppTypography.caption),
                        Text('(Tap map to fine tune pin location)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                        const Text('Save Address As', style: AppTypography.itemName),
                        const SizedBox(height: 10),
                        Row(
                          children: AddressType.values.map((type) {
                            final isSelected = _addressType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _addressType = type),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryTint20 : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    type.label,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                          controller: _landmarkController,
                          label: 'Apartment Road / Landmark',
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
                          title: const Text('Set as default delivery address', style: AppTypography.bodySmall),
                          onChanged: (val) => setState(() => _isDefault = val ?? false),
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
                  BoxShadow(color: Color(0x14171A14), offset: Offset(0, -4), blurRadius: 16),
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
