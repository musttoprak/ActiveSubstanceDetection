// lib/services/forum_service.dart
import 'package:mobile/models/request_models/forum_post_model.dart';
import 'package:mobile/models/request_models/forum_request_models.dart';

import '../models/api_response.dart';
import 'api_service.dart';

class ForumService {
  // Tüm gönderileri getir
  static Future<ApiResponse<List<ForumPost>>> getPosts({String? category, String? query}) async {
    String endpoint = '/forum/posts';

    // URL parametreleri
    final queryParams = <String, String>{};
    if (category != null && category != 'Tümü') {
      queryParams['category'] = category;
    }
    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }

    // Query parametreleri varsa URL'e ekle
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint = '$endpoint?$queryString';
    }

    return await ApiService.get<List<ForumPost>>(
      endpoint,
          (data) {
        if (data is Map && data.containsKey('data')) {
          return List<ForumPost>.from(
            data['data'].map((x) => ForumPost.fromJson(x)),
          );
        }
        return [];
      },
    );
  }

  // Gönderi detayını getir
  static Future<ApiResponse<ForumPost>> getPost(int postId) async {
    return await ApiService.get<ForumPost>(
      '/forum/posts/$postId',
          (data) => ForumPost.fromJson(data),
    );
  }

  // Yeni gönderi oluştur
  static Future<ApiResponse<ForumPost>> createPost(CreatePostRequest request) async {
    return await ApiService.post<ForumPost>(
      '/forum/posts',
      request.toJson(),
          (data) => ForumPost.fromJson(data),
    );
  }

  // Gönderiyi güncelle
  static Future<ApiResponse<ForumPost>> updatePost(
      int postId,
      CreatePostRequest request,
      {bool? isResolved}
      ) async {
    final requestData = Map<String, dynamic>.from(request.toJson());
    if (isResolved != null) {
      requestData['is_resolved'] = isResolved;
    }

    return await ApiService.put<ForumPost>(
      '/forum/posts/$postId',
      requestData,
          (data) => ForumPost.fromJson(data),
    );
  }

  // Gönderiyi sil
  static Future<ApiResponse<void>> deletePost(int postId) async {
    return await ApiService.delete<void>(
      '/forum/posts/$postId',
          (_) => null,
    );
  }

  // Yorum ekle
  static Future<ApiResponse<ForumComment>> addComment(int postId, AddCommentRequest request) async {
    return await ApiService.post<ForumComment>(
      '/forum/posts/$postId/comments',
      request.toJson(),
          (data) => ForumComment.fromJson(data),
    );
  }

  // Yorumu güncelle
  static Future<ApiResponse<ForumComment>> updateComment(int commentId, AddCommentRequest request) async {
    return await ApiService.put<ForumComment>(
      '/forum/comments/$commentId',
      request.toJson(),
          (data) => ForumComment.fromJson(data),
    );
  }

  // Yorumu sil
  static Future<ApiResponse<void>> deleteComment(int commentId) async {
    return await ApiService.delete<void>(
      '/forum/comments/$commentId',
          (_) => null,
    );
  }

  // Yorumu kabul et
  static Future<ApiResponse<ForumComment>> acceptComment(int commentId) async {
    return await ApiService.post<ForumComment>(
      '/forum/comments/$commentId/accept',
      {},
          (data) => ForumComment.fromJson(data),
    );
  }

  // Beğeni işlemi
  static Future<ApiResponse<Map<String, dynamic>>> like(LikeRequest request) async {
    return await ApiService.post<Map<String, dynamic>>(
      '/forum/like',
      request.toJson(),
          (data) => {
        'liked': data['liked'] ?? false,
      },
    );
  }
}