


class Comment {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String content;
  final DateTime createdAt;
  final String? userPhotoUrl;

  Comment({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.userPhotoUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      userId: map['userId'],
      userEmail: map['userEmail'],
      userName: map['userName'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      userPhotoUrl: map['userPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'userPhotoUrl': userPhotoUrl,
    };
  }
}