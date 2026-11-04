class OfferModel {
  final String code;
  final String title;
  final String description;
  final double discountAmount;
  final double minimumOrderAmount;
  final bool isApplicable;
  final String? ineligibilityReason;

  const OfferModel({
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    this.minimumOrderAmount = 0.0,
    this.isApplicable = true,
    this.ineligibilityReason,
  });
}

