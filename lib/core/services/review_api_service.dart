import '../network/api_client.dart';
import '../constants/api_constants.dart';

class ReviewItemRating {
  final String menuItemId;
  final String name;
  final bool isRecommended;
  final String? comment;

  const ReviewItemRating({
    required this.menuItemId,
    required this.name,
    this.isRecommended = true,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'name': name,
        'isRecommended': isRecommended,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };

  factory ReviewItemRating.fromJson(Map<String, dynamic> json) =>
      ReviewItemRating(
        menuItemId: json['menuItemId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        isRecommended: json['isRecommended'] == true,
        comment: json['comment']?.toString(),
      );
}

class StoreReviewModel {
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final int helpfulCount;
  final String? storeReply;
  final DateTime? repliedAt;
  final DateTime createdAt;

  const StoreReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.helpfulCount,
    this.storeReply,
    this.repliedAt,
    required this.createdAt,
  });

  factory StoreReviewModel.fromJson(Map<String, dynamic> json) {
    final replyMap = json['storeReply'] is Map<String, dynamic>
        ? json['storeReply'] as Map<String, dynamic>
        : null;

    final createdStr = json['createdAt']?.toString();
    final repliedStr = replyMap?['repliedAt']?.toString();

    return StoreReviewModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Customer',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      helpfulCount: (json['helpfulCount'] as num?)?.toInt() ?? 0,
      storeReply: replyMap?['comment']?.toString(),
      repliedAt: repliedStr != null ? DateTime.tryParse(repliedStr) : null,
      createdAt:
          createdStr != null ? (DateTime.tryParse(createdStr) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class StoreReviewsSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starBreakdown;
  final List<StoreReviewModel> reviews;

  const StoreReviewsSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.starBreakdown,
    required this.reviews,
  });

  factory StoreReviewsSummary.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawBreakdown = stats['starBreakdown'] is Map<String, dynamic>
        ? stats['starBreakdown'] as Map<String, dynamic>
        : <String, dynamic>{};

    final Map<int, int> breakdown = {};
    for (int i = 1; i <= 5; i++) {
      breakdown[i] = (rawBreakdown['$i'] as num?)?.toInt() ?? 0;
    }

    final rawReviews = json['reviews'] is List ? json['reviews'] as List : const [];
    final parsedReviews = rawReviews
        .whereType<Map<String, dynamic>>()
        .map((e) => StoreReviewModel.fromJson(e))
        .toList();

    return StoreReviewsSummary(
      averageRating: (stats['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (stats['totalReviews'] as num?)?.toInt() ?? 0,
      starBreakdown: breakdown,
      reviews: parsedReviews,
    );
  }
}

class ReviewApiService {
  final ApiClient _client;

  ReviewApiService({ApiClient? client}) : _client = client ?? globalApiClient;

  /// Submit review for a delivered order
  /// POST /reviews
  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    required String comment,
    List<String>? foodTags,
    List<ReviewItemRating>? itemRatings,
    int? driverRating,
    List<String>? driverTags,
    String? driverComment,
  }) async {
    final body = <String, dynamic>{
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      if (foodTags != null && foodTags.isNotEmpty) 'foodTags': foodTags,
      if (itemRatings != null && itemRatings.isNotEmpty)
        'itemRatings': itemRatings.map((e) => e.toJson()).toList(),
      if (driverRating != null) 'driverRating': driverRating,
      if (driverTags != null && driverTags.isNotEmpty) 'driverTags': driverTags,
      if (driverComment != null && driverComment.isNotEmpty)
        'driverComment': driverComment,
    };

    final res = await _client.post(ApiConstants.reviews, body: body);
    return res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {};
  }

  /// Get customer's submitted review for an order
  /// GET /reviews/order/{orderId}
  Future<Map<String, dynamic>?> getOrderReview(String orderId) async {
    try {
      final res = await _client.get(ApiConstants.reviewOrder(orderId));
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Edit submitted review within 7 days
  /// PUT /reviews/{id}
  Future<Map<String, dynamic>> editReview(
    String reviewId, {
    int? rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
    };

    final res = await _client.put(ApiConstants.reviewById(reviewId), body: body);
    return res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {};
  }

  /// Fetch public store reviews feed with statistics
  /// GET /reviews/store/{storeId}
  Future<StoreReviewsSummary> getStoreReviews(
    String storeId, {
    int page = 1,
    int limit = 10,
    int? rating,
    String sortBy = 'NEWEST',
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
    };
    if (rating != null) qp['rating'] = rating;

    final res = await _client.get(ApiConstants.reviewStore(storeId), queryParams: qp);
    if (res.data is Map<String, dynamic>) {
      return StoreReviewsSummary.fromJson(res.data as Map<String, dynamic>);
    }
    return const StoreReviewsSummary(
      averageRating: 0.0,
      totalReviews: 0,
      starBreakdown: {},
      reviews: [],
    );
  }

  /// Upvote a review as helpful
  /// POST /reviews/{id}/helpful
  Future<int> markHelpful(String reviewId) async {
    final res = await _client.post(ApiConstants.reviewHelpful(reviewId));
    if (res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      return (map['helpfulCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}

final reviewApiService = ReviewApiService();

