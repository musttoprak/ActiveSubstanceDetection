import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/models/request_models/update_profile_request.dart';
import 'package:mobile/models/response_models/user_model.dart';
import 'package:mobile/service/user_service.dart';
import 'dart:io';

// State
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserProfile profile;

  const UserLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitial());

  // Kullanıcı profili yükle
  Future<void> getUserProfile() async {
    emit(UserLoading());

    final response = await UserService.getProfile();

    if (response.success && response.data != null) {
      emit(UserLoaded(response.data!));
    } else {
      emit(UserError(response.message));
    }
  }

  // Profil güncelle
  Future<bool> updateProfile({String? name, String? role, File? profilePicture}) async {
    emit(UserLoading());

    final request = UpdateProfileRequest(
      name: name,
      role: role,
      profilePicture: profilePicture,
    );

    final response = await UserService.updateProfile(request);

    if (response.success && response.data != null) {
      emit(UserLoaded(response.data!));
      return true;
    } else {
      emit(UserError(response.message));
      return false;
    }
  }
}