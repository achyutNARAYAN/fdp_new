import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum DietType {
  veg('Veg', AppColors.vegGreen),
  nonVeg('Non-veg', AppColors.nonVegBrown),
  egg('Contains Egg', AppColors.eggYellow);

  final String label;
  final Color color;

  const DietType(this.label, this.color);
}

