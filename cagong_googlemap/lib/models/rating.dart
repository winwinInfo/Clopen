class RatingStats {
  final double averageRating;
  final int totalCount;
  final int? myRating;
  final int? myConsentRate;
  final int? mySeatRate;
  final String? consentKeyword;
  final String? seatKeyword;
  final Map<String, int> ratingDistribution;
  final Map<String, int> consentDistribution;
  final Map<String, int> seatDistribution;


  RatingStats({
    required this.averageRating,
    required this.totalCount,
    this.myRating,
    this.myConsentRate,
    this.mySeatRate,
    this.consentKeyword,
    this.seatKeyword,
    required this.ratingDistribution,
    required this.consentDistribution,
    required this.seatDistribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalCount: json['total_count'] as int,
      myRating: json['my_rating'] as int?,
      myConsentRate: json['my_consent_rate'] as int?,
      mySeatRate: json['my_seat_rate'] as int?,
      consentKeyword: json['consent_keyword'] as String?,
      seatKeyword: json['seat_keyword'] as String?,
      ratingDistribution: Map<String, int>.from(json['rating_distribution']),
      consentDistribution: Map<String, int>.from(json['consent_distribution'] ?? {}),
      seatDistribution: Map<String, int>.from(json['seat_distribution'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_rating': averageRating,
      'total_count': totalCount,
      'my_rating': myRating,
      'my_consent_rate': myConsentRate,
      'my_seat_rate': mySeatRate,
      'consent_keyword': consentKeyword,
      'seat_keyword': seatKeyword,
      'rating_distribution': ratingDistribution,
      'consent_distribution': consentDistribution,
      'seat_distribution': seatDistribution,
    };
  }
}



class Rating {
  final int id;
  final int userId;
  final int cafeId;
  final int? rate;
  final int? consentRate;
  final int? seatRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    required this.id,
    required this.userId,
    required this.cafeId,
    this.rate,
    this.consentRate,
    this.seatRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      cafeId: json['cafe_id'] as int,
      rate: json['rate'] as int?,
      consentRate: json['consent_rate'] as int?,
      seatRate: json['seat_rate'] as int?,
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
      'consent_rate': consentRate,
      'seat_rate': seatRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
