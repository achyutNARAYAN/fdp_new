import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMap extends StatelessWidget {
  final LatLng? center;
  final double height;

  const LocationMap({super.key, required this.center, this.height = 280});

  @override
  Widget build(BuildContext context) {
    final location = center ?? const LatLng(0, 0);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey(center),
              options: MapOptions(
                initialCenter: location,
                initialZoom: center == null ? 1.5 : 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fdp',
                ),
                if (center != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center!,
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
            if (center == null)
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
      ),
    );
  }
}
