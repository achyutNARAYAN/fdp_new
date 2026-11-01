import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import '../../shared/widgets/badges/status_chip.dart';
import '../../shared/widgets/buttons/app_primary_button.dart';
import '../../shared/widgets/buttons/app_secondary_button.dart';

enum LocationUiState {
  serviceable,
  nonServiceable,
  permissionRequired,
  gpsOff,
  allShopsClosed,
}

class DeliveryLocationScreen extends ConsumerStatefulWidget {
  const DeliveryLocationScreen({super.key});

  @override
  ConsumerState<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends ConsumerState<DeliveryLocationScreen> {
  LocationUiState _uiState = LocationUiState.serviceable;
  String _selectedAddressTitle = 'Indiranagar 100ft Road';
  String _selectedAddressSubtitle = 'Indiranagar, Bengaluru, Karnataka 560038';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Delivery Location'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Top 55%: Map view with custom pin
          Expanded(
            flex: 55,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stylized greyscale map representation
                Container(
                  color: const Color(0xFFE8ECE9),
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                    child: Container(),
                  ),
                ),

                // Center Draggable Pin
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.accent, // Burnt Amber center dot
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 16,
                      color: AppColors.textPrimary,
                    ),
                    Container(
                      width: 14,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),

                // Top Search & Current Location Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                      boxShadow: AppDimensions.elevationLevel2,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Search area, landmark or apartment...',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, color: AppColors.accent, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _uiState = LocationUiState.serviceable;
                              _selectedAddressTitle = 'Indiranagar 8th Main';
                              _selectedAddressSubtitle = 'Lotus Orchid, Indiranagar, Bengaluru 560038';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Prototype state testing bar
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _stateBtn('Serviceable', LocationUiState.serviceable),
                        _stateBtn('Non-serviceable', LocationUiState.nonServiceable),
                        _stateBtn('Closed', LocationUiState.allShopsClosed),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom 45%: Bottom Sheet with Serviceability Status & Details
          Expanded(
            flex: 45,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.p20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusBottomSheet),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14171A14),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Serviceability chip
                    _buildServiceabilityHeader(),
                    const SizedBox(height: 16),

                    // Pinpoint details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.accent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedAddressTitle, style: AppTypography.itemName),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddressSubtitle,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Change', style: TextStyle(color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Actions based on state
                    if (_uiState == LocationUiState.serviceable) ...[
                      AppPrimaryButton(
                        label: 'Confirm Location & Explore',
                        onPressed: () {
                          context.go('/home');
                        },
                      ),
                    ] else if (_uiState == LocationUiState.nonServiceable) ...[
                      AppSecondaryButton(
                        label: 'Notify me when you deliver here',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you! We will notify you once we launch in this area.')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      AppPrimaryButton(
                        label: 'Try Another Location',
                        onPressed: () {
                          setState(() => _uiState = LocationUiState.serviceable);
                        },
                      ),
                    ] else if (_uiState == LocationUiState.allShopsClosed) ...[
                      AppPrimaryButton(
                        label: 'Browse & Schedule for Later',
                        onPressed: () {
                          context.go('/home');
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceabilityHeader() {
    switch (_uiState) {
      case LocationUiState.serviceable:
        return const Row(
          children: [
            Expanded(
              child: StatusChip(
                label: 'Serviceable • 12 Shops Delivering',
                type: StatusChipType.success,
              ),
            ),
            SizedBox(width: 8),
            Text('Cold-chain available', style: AppTypography.caption),
          ],
        );
      case LocationUiState.nonServiceable:
        return const Row(
          children: [
            Expanded(
              child: StatusChip(
                label: 'Sorry, we don’t currently deliver here',
                type: StatusChipType.error,
              ),
            ),
          ],
        );
      case LocationUiState.allShopsClosed:
        return const Row(
          children: [
            Expanded(
              child: StatusChip(
                label: 'Shops near you are closed right now',
                type: StatusChipType.info,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stateBtn(String label, LocationUiState state) {
    final active = _uiState == state;
    return GestureDetector(
      onTap: () => setState(() => _uiState = state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0;

    final paintPark = Paint()
      ..color = const Color(0xFFD4E2D4)
      ..style = PaintingStyle.fill;

    // Draw some stylized parks
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(20, 40, size.width * 0.35, 100), const Radius.circular(16)),
      paintPark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.6, size.height * 0.5, size.width * 0.3, 120), const Radius.circular(16)),
      paintPark,
    );

    // Draw stylized roads
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.45), paintRoad);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.45, size.height), paintRoad);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.65), paintRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
