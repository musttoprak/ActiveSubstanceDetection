import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/models/request_models/forum_post_model.dart';
import 'package:mobile/models/request_models/forum_request_models.dart';
import 'package:mobile/service/forum_service.dart';

// State
abstract class ForumPostState extends Equatable {
  const ForumPostState();

  @override
  List<Object?> get props => [];
}

class ForumPostInitial extends ForumPostState {}

class ForumPostLoading extends ForumPostState {}

class ForumPostLoaded extends ForumPostState {
  final List<ForumPost> posts;
  final String? category;
  final String? searchQuery;

  const ForumPostLoaded({
    required this.posts,
    this.category,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [posts, category, searchQuery];
}

class ForumPostError extends ForumPostState {
  final String message;

  const ForumPostError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class ForumPostCubit extends Cubit<ForumPostState> {
  ForumPostCubit() : super(ForumPostInitial());

  // Gönderileri yükle
  Future<void> getPosts({String? category, String? query}) async {
    emit(ForumPostLoading());

    final response = await ForumService.getPosts(
      category: category,
      query: query,
    );

    if (response.success) {
      emit(ForumPostLoaded(
        posts: response.data ?? [],
        category: category,
        searchQuery: query,
      ));
    } else {
      emit(ForumPostError(response.message));
    }
  }

  // Yeni gönderi oluştur
  Future<bool> createPost(CreatePostRequest request) async {
    emit(ForumPostLoading());

    final response = await ForumService.createPost(request);

    if (response.success) {
      // Gönderileri yeniden yükle
      await getPosts(
        category: state is ForumPostLoaded ? (state as ForumPostLoaded).category : null,
        query: state is ForumPostLoaded ? (state as ForumPostLoaded).searchQuery : null,
      );
      return true;
    } else {
      emit(ForumPostError(response.message));
      return false;
    }
  }

  // Gönderiyi sil
  Future<bool> deletePost(int postId) async {
    final currentState = state;
    if (currentState is ForumPostLoaded) {
      final updatedPosts = List<ForumPost>.from(currentState.posts)
        ..removeWhere((post) => post.id == postId);

      emit(ForumPostLoaded(
        posts: updatedPosts,
        category: currentState.category,
        searchQuery: currentState.searchQuery,
      ));
    }

    final response = await ForumService.deletePost(postId);

    if (response.success) {
      return true;
    } else {
      // Hata durumunda eski listeyi geri yükle
      await getPosts(
        category: state is ForumPostLoaded ? (state as ForumPostLoaded).category : null,
        query: state is ForumPostLoaded ? (state as ForumPostLoaded).searchQuery : null,
      );
      return false;
    }
  }
}
