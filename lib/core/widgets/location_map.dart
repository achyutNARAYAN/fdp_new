import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

class LocationMap extends StatefulWidget {
  final LatLng? center;
  final double? height;
  final ValueChanged<LatLng>? onTap;
  final MapController? controller;
  final bool showZoomControls;

  const LocationMap({
    super.key,
    required this.center,
    this.height = 280,
    this.onTap,
    this.controller,
    this.showZoomControls = true,
  });

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late MapController _mapController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _mapController = widget.controller!;
      _ownsController = false;
    } else {
      _mapController = MapController();
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _mapController.dispose();
      }
      _mapController = widget.controller!;
      _ownsController = false;
    }

    if (widget.center != null && widget.center != oldWidget.center) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final camera = _mapController.camera;
          final targetZoom = camera.zoom < 10.0 ? 15.0 : camera.zoom;
          _mapController.move(widget.center!, targetZoom);
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _mapController.dispose();
    }
    super.dispose();
  }

  void _zoomIn() {
    try {
      final camera = _mapController.camera;
      final maxZoom = camera.maxZoom ?? 19.0;
      final nextZoom = (camera.zoom + 1.0).clamp(camera.minZoom ?? 3.0, maxZoom);
      _mapController.move(camera.center, nextZoom);
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final camera = _mapController.camera;
      final minZoom = camera.minZoom ?? 3.0;
      final nextZoom = (camera.zoom - 1.0).clamp(minZoom, camera.maxZoom ?? 19.0);
      _mapController.move(camera.center, nextZoom);
    } catch (_) {}
  }

  void _recenter() {
    if (widget.center != null) {
      try {
        final camera = _mapController.camera;
        final targetZoom = camera.zoom < 12.0 ? 15.0 : camera.zoom;
        _mapController.move(widget.center!, targetZoom);
      } catch (_) {}
    }
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Default to Bihar / Champaran coordinates if center is not yet selected
    final defaultCenter = widget.center ?? const LatLng(27.0988, 84.0900);

    final mapWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultCenter,
              initialZoom: widget.center == null ? 6.0 : 15.0,
              minZoom: 3.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: widget.onTap == null ? null : (_, point) => widget.onTap!(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fdp',
              ),
              if (widget.center != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.center!,
                      width: 44,
                      height: 52,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (widget.showZoomControls)
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: AppColors.neutralBorder.withValues(alpha: 0.25),
                  ),
                ),
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapButton(
                      icon: Icons.add,
                      tooltip: 'Zoom in',
                      onTap: _zoomIn,
                    ),
                    Container(
                      width: 30,
                      height: 1,
                      color: AppColors.divider,
                    ),
                    _buildMapButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom out',
                      onTap: _zoomOut,
                    ),
                    if (widget.center != null) ...[
                      Container(
                        width: 30,
                        height: 1,
                        color: AppColors.divider,
                      ),
                      _buildMapButton(
                        icon: Icons.my_location,
                        tooltip: 'Center on pin',
                        onTap: _recenter,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              color: Colors.white.withValues(alpha: 0.85),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ),
          if (widget.center == null)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Use current location to pin your address'),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        child: mapWidget,
      );
    }
    return mapWidget;
  }
}
