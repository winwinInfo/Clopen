class RatingStats {
  final double averageRating;
  final int totalCount;
  final int? myRating;
  final Map<String, int> ratingDistribution;

  RatingStats({
    required this.averageRating,
    required this.totalCount,
    this.myRating,
    required this.ratingDistribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalCount: json['total_count'] as int,
      myRating: json['my_rating'] as int?,
      ratingDistribution: Map<String, int>.from(json['rating_distribution']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_rating': averageRating,
      'total_count': totalCount,
      'my_rating': myRating,
      'rating_distribution': ratingDistribution,
    };
  }
}

class Rating {
  final int id;
  final int userId;
  final int cafeId;
  final int rate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    required this.id,
    required this.userId,
    required this.cafeId,
    required this.rate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      cafeId: json['cafe_id'] as int,
      rate: json['rate'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cafe_id': cafeId,
      'rate': rate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
