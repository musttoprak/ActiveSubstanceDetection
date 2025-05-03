// lib/cubits/forum/forum_detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/models/request_models/forum_post_model.dart';
import 'package:mobile/models/request_models/forum_request_models.dart';
import 'package:mobile/service/forum_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/api_response.dart';

// State
abstract class ForumDetailState extends Equatable {
  const ForumDetailState();

  @override
  List<Object?> get props => [];
}

class ForumDetailInitial extends ForumDetailState {}

class ForumDetailLoading extends ForumDetailState {}

class ForumDetailLoaded extends ForumDetailState {
  final ForumPost post;
  final Map<String, dynamic>? userLikes;

  const ForumDetailLoaded({
    required this.post,
    this.userLikes,
  });

  bool isPostLiked() {
    return userLikes != null && userLikes!['post'] == true;
  }

  bool isCommentLiked(int commentId) {
    return userLikes != null &&
        userLikes!['comments'] is List &&
        (userLikes!['comments'] as List).contains(commentId);
  }

  @override
  List<Object?> get props => [post, userLikes];
}

class ForumDetailError extends ForumDetailState {
  final String message;

  const ForumDetailError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class ForumDetailCubit extends Cubit<ForumDetailState> {
  ForumDetailCubit() : super(ForumDetailInitial());

  // Gönderi detayını yükle
  Future<void> getPostDetail(int postId) async {
    emit(ForumDetailLoading());

    final ApiResponse<ForumPost> response = await ForumService.getPost(postId);

    if (response.success && response.data != null) {
      // userLikes bilgisi API yanıtının içindeki 'user_likes' alanından alınır
      // eğer bu alan yoksa boş bir Map kullanılır
      final Map<String, dynamic> userLikes = (response.rawData != null && response.rawData!['user_likes'] != null)
          ? (response.rawData!['user_likes'] is List
          ? {}  // Boş bir liste geldiğinde boş bir Map döndür
          : Map<String, dynamic>.from(response.rawData!['user_likes']))
          : {};  // response.rawData['user_likes'] null ise boş bir Map döndür


      emit(ForumDetailLoaded(
        post: response.data!,
        userLikes: userLikes,
      ));
    } else {
      emit(ForumDetailError(response.message));
    }
  }

  // Gönderiyi sil
  Future<bool> deletePost(int postId) async {
    try {
      final ApiResponse<void> response = await ForumService.deletePost(postId);

      if (response.success) {
        return true;
      } else {
        emit(ForumDetailError(response.message));
        return false;
      }
    } catch (e) {
      emit(ForumDetailError(e.toString()));
      return false;
    }
  }

  // Yorum ekle
  Future<bool> addComment(int postId, AddCommentRequest request) async {
    final currentState = state;
    if (currentState is! ForumDetailLoaded) return false;

    try {
      final ApiResponse<ForumComment> response = await ForumService.addComment(postId, request);

      if (response.success && response.data != null) {
        final updatedPost = currentState.post;
        final updatedComments = List<ForumComment>.from(updatedPost.comments)
          ..add(response.data!);

        final newPost = ForumPost(
          id: updatedPost.id,
          userId: updatedPost.userId,
          title: updatedPost.title,
          content: updatedPost.content,
          category: updatedPost.category,
          likes: updatedPost.likes,
          isResolved: updatedPost.isResolved,
          createdAt: updatedPost.createdAt,
          updatedAt: updatedPost.updatedAt,
          author: updatedPost.author,
          comments: updatedComments,
          commentsCount: updatedPost.commentsCount + 1,
        );

        emit(ForumDetailLoaded(
          post: newPost,
          userLikes: currentState.userLikes,
        ));
        return true;
      } else {
        emit(ForumDetailError(response.message));
        return false;
      }
    } catch (e) {
      emit(ForumDetailError(e.toString()));
      return false;
    }
  }

  // Yorumu kabul et
  Future<bool> acceptComment(int commentId) async {
    final currentState = state;
    if (currentState is! ForumDetailLoaded) return false;

    try {
      final ApiResponse<ForumComment> response = await ForumService.acceptComment(commentId);

      if (response.success) {
        // Gönderiyi yeniden yükle
        await getPostDetail(currentState.post.id);
        return true;
      } else {
        emit(ForumDetailError(response.message));
        return false;
      }
    } catch (e) {
      emit(ForumDetailError(e.toString()));
      return false;
    }
  }

  // Gönderiyi beğen
  Future<bool> likePost(int postId) async {
    final currentState = state;
    if (currentState is! ForumDetailLoaded) return false;

    // UI'da hemen güncelle
    final isCurrentlyLiked = currentState.isPostLiked();
    final updatedLikes = currentState.post.likes + (isCurrentlyLiked ? -1 : 1);

    final updatedPost = ForumPost(
      id: currentState.post.id,
      userId: currentState.post.userId,
      title: currentState.post.title,
      content: currentState.post.content,
      category: currentState.post.category,
      likes: updatedLikes,
      isResolved: currentState.post.isResolved,
      createdAt: currentState.post.createdAt,
      updatedAt: currentState.post.updatedAt,
      author: currentState.post.author,
      comments: currentState.post.comments,
      commentsCount: currentState.post.commentsCount,
    );

    Map<String, dynamic> updatedUserLikes = Map<String, dynamic>.from(currentState.userLikes ?? {});
    updatedUserLikes['post'] = !isCurrentlyLiked;

    emit(ForumDetailLoaded(
      post: updatedPost,
      userLikes: updatedUserLikes,
    ));

    // API'ya gönder
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');

      final ApiResponse<Map<String, dynamic>> response = await ForumService.like(
        LikeRequest(userId: id.toString(),likeableId: postId, likeableType: 'post'),
      );

      if (!response.success) {
        // Hata durumunda eski hali geri yükle
        await getPostDetail(postId);
        return false;
      }

      return true;
    } catch (e) {
      // Hata durumunda eski hali geri yükle
      await getPostDetail(postId);
      return false;
    }
  }

  // Yorumu beğen
  Future<bool> likeComment(int commentId) async {
    final currentState = state;
    if (currentState is! ForumDetailLoaded) return false;

    // UI'da hemen güncelle
    final isCurrentlyLiked = currentState.isCommentLiked(commentId);

    final updatedComments = currentState.post.comments.map((comment) {
      if (comment.id == commentId) {
        return ForumComment(
          id: comment.id,
          postId: comment.postId,
          content: comment.content,
          likes: comment.likes + (isCurrentlyLiked ? -1 : 1),
          isAccepted: comment.isAccepted,
          createdAt: comment.createdAt,
          author: comment.author,
        );
      }
      return comment;
    }).toList();

    final updatedPost = ForumPost(
      id: currentState.post.id,
      userId: currentState.post.userId,
      title: currentState.post.title,
      content: currentState.post.content,
      category: currentState.post.category,
      likes: currentState.post.likes,
      isResolved: currentState.post.isResolved,
      createdAt: currentState.post.createdAt,
      updatedAt: currentState.post.updatedAt,
      author: currentState.post.author,
      comments: updatedComments,
      commentsCount: currentState.post.commentsCount,
    );

    Map<String, dynamic> updatedUserLikes = Map<String, dynamic>.from(currentState.userLikes ?? {});
    List<int> commentLikes = List<int>.from(updatedUserLikes['comments'] ?? []);

    if (isCurrentlyLiked) {
      commentLikes.remove(commentId);
    } else {
      commentLikes.add(commentId);
    }

    updatedUserLikes['comments'] = commentLikes;

    emit(ForumDetailLoaded(
      post: updatedPost,
      userLikes: updatedUserLikes,
    ));

    // API'ya gönder
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('id');

      final ApiResponse<Map<String, dynamic>> response = await ForumService.like(
        LikeRequest(userId: id.toString() ,likeableId: commentId, likeableType: 'comment'),
      );

      if (!response.success) {
        // Hata durumunda eski hali geri yükle
        await getPostDetail(currentState.post.id);
        return false;
      }

      return true;
    } catch (e) {
      // Hata durumunda eski hali geri yükle
      await getPostDetail(currentState.post.id);
      return false;
    }
  }

  // Gönderiyi "çözüldü" olarak işaretle/işareti kaldır
  Future<bool> toggleResolved(int postId, bool isResolved) async {
    final currentState = state;
    if (currentState is! ForumDetailLoaded) return false;

    // UI'da hemen güncelle
    final updatedPost = ForumPost(
      id: currentState.post.id,
      userId: currentState.post.userId,
      title: currentState.post.title,
      content: currentState.post.content,
      category: currentState.post.category,
      likes: currentState.post.likes,
      isResolved: isResolved,
      createdAt: currentState.post.createdAt,
      updatedAt: currentState.post.updatedAt,
      author: currentState.post.author,
      comments: currentState.post.comments,
      commentsCount: currentState.post.commentsCount,
    );

    emit(ForumDetailLoaded(
      post: updatedPost,
      userLikes: currentState.userLikes,
    ));

    // API'ya gönder
    try {
      final request = CreatePostRequest(
        userId: currentState.post.userId,
        title: currentState.post.title,
        content: currentState.post.content,
        category: currentState.post.category,
      );

      final ApiResponse<ForumPost> response = await ForumService.updatePost(
          postId,
          request,
          isResolved: isResolved
      );

      if (!response.success) {
        // Hata durumunda eski hali geri yükle
        await getPostDetail(postId);
        return false;
      }

      return true;
    } catch (e) {
      // Hata durumunda eski hali geri yükle
      await getPostDetail(postId);
      return false;
    }
  }
}