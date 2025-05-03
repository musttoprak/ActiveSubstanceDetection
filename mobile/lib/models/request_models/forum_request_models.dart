class CreatePostRequest {
  final String userId;
  final String title;
  final String content;
  final String category;

  CreatePostRequest({
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'content2': content,
      'category': category,
    };
  }
}

class AddCommentRequest {
  final String userId;
  final String content;

  AddCommentRequest({
    required this.userId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'content2': content,
    };
  }
}

class LikeRequest {
  final String userId;
  final int likeableId;
  final String likeableType; // 'post' veya 'comment'

  LikeRequest({
    required this.userId,
    required this.likeableId,
    required this.likeableType,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'likeable_id': likeableId,
      'likeable_type': likeableType,
    };
  }
}
