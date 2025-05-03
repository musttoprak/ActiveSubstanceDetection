import 'dart:convert';

class ForumPost {
  final int id;
  final String userId;
  final String title;
  final String content;
  final String category;
  final int likes;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ForumAuthor author;
  final List<ForumComment> comments;
  final int commentsCount;

  ForumPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.likes,
    required this.isResolved,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.comments,
    required this.commentsCount,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    List<ForumComment> commentsList = [];
    if (json['comments'] != null) {
      commentsList = List<ForumComment>.from(
        json['comments'].map((x) => ForumComment.fromJson(x)),
      );
    }

    return ForumPost(
      id: json['id'],
      userId: json['user_id'].toString(),
      title: json['title'],
      content: json['content'],
      category: json['category'],
      likes: json['likes'] ?? 0,
      isResolved: json['is_resolved'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      author: ForumAuthor.fromJson(json['user']),
      comments: commentsList,
      commentsCount: json['comments_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content2': content,
      'category': category,
      'likes': likes,
      'is_resolved': isResolved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': author.toJson(),
      'comments': comments.map((x) => x.toJson()).toList(),
      'comments_count': commentsCount,
    };
  }
}

class ForumAuthor {
  final int id;
  final String email;
  final String name;
  final String role;
  final String? profilePicture;

  ForumAuthor({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profilePicture,
  });

  factory ForumAuthor.fromJson(Map<String, dynamic> json) {
    return ForumAuthor(
      id: json['id'],
      email: json['email'],
      name: json['detail'] != null ? json['detail']['name'] : 'Kullanıcı',
      role: json['detail'] != null ? json['detail']['role'] : 'Eczacı',
      profilePicture: json['detail'] != null ? json['detail']['profile_picture'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'detail': {
        'name': name,
        'role': role,
        'profile_picture': profilePicture,
      },
    };
  }
}

class ForumComment {
  final int id;
  final int postId;
  final int likes;
  final String content;
  final bool isAccepted;
  final DateTime createdAt;
  final ForumAuthor author;

  ForumComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.likes,
    required this.isAccepted,
    required this.createdAt,
    required this.author,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'],
      postId: int.tryParse(json['post_id'].toString()) ?? 0,
      content: json['content'],
      likes: json['likes'] ?? 0,
      isAccepted: json['is_accepted'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      author: ForumAuthor.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'content2': content,
      'likes': likes,
      'is_accepted': isAccepted,
      'created_at': createdAt.toIso8601String(),
      'user': author.toJson(),
    };
  }
}