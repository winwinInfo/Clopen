class Comment {
  final int id;
  final int userId;
  final String userNickname;
  final String? userPhoto;
  final int cafeId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userNickname,
    this.userPhoto,
    required this.cafeId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userNickname: json['user_nickname'] as String,
      userPhoto: json['user_photo'] as String?,
      cafeId: json['cafe_id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_nickname': userNickname,
      'user_photo': userPhoto,
      'cafe_id': cafeId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}