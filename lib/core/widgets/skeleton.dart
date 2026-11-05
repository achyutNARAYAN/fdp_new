import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Sweeping shimmer gradient animation wrapper
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double progress = _controller.value;
            // Sweep from -1.0 to 2.0 to give smooth entry and exit of highlight
            return LinearGradient(
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              stops: [
                (progress - 0.25).clamp(0.0, 1.0),
                progress.clamp(0.0, 1.0),
                (progress + 0.25).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE2E5E0),
                Color(0xFFF6F8F5),
                Color(0xFFE2E5E0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Generic rounded rectangle skeleton block
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: const Color(0xFFE2E5E0),
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
      ),
    );
  }
}

/// Swiggy / Zomato style search suggestions skeleton loader
class SearchSkeletonLoading extends StatelessWidget {
  const SearchSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Sweets / Dishes Skeleton Header
          Row(
            children: const [
              SkeletonBox(width: 140, height: 16, borderRadius: 4),
              Spacer(),
              SkeletonBox(width: 36, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Item suggestion skeleton rows
          for (int i = 0; i < 4; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SkeletonBox(width: 52, height: 52, borderRadius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          width: i.isEven ? 160 : 130,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 6),
                        SkeletonBox(
                          width: i.isEven ? 100 : 120,
                          height: 11,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 6),
                        const SkeletonBox(width: 55, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SkeletonBox(width: 20, height: 20, borderRadius: 10),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.divider.withValues(alpha: 0.15),
            ),
          ],

          const SizedBox(height: 20),

          // Section 2: Shops / Stores Skeleton Header
          Row(
            children: const [
              SkeletonBox(width: 120, height: 16, borderRadius: 4),
              Spacer(),
              SkeletonBox(width: 36, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 12),

          // 2 Shop suggestion skeleton rows
          for (int i = 0; i < 2; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SkeletonBox(width: 48, height: 48, borderRadius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(
                          width: i == 0 ? 150 : 130,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 6),
                        const SkeletonBox(
                          width: 110,
                          height: 11,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SkeletonBox(width: 44, height: 20, borderRadius: 6),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.divider.withValues(alpha: 0.15),
            ),
          ],
        ],
      ),
    );
  }
}

