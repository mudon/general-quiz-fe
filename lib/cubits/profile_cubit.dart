import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user.dart';
import '../services/profile_service.dart';

class ProfileState {
  final User? user;
  final bool loading;
  final String? error;
  final bool editing;
  final bool saving;
  final bool changingPassword;
  final bool showPasswordSection;
  final bool changingEmail;
  final bool showEmailSection;

  const ProfileState({
    this.user,
    this.loading = true,
    this.error,
    this.editing = false,
    this.saving = false,
    this.changingPassword = false,
    this.showPasswordSection = false,
    this.changingEmail = false,
    this.showEmailSection = false,
  });

  ProfileState copyWith({
    User? user,
    bool? loading,
    String? error,
    bool? editing,
    bool? saving,
    bool? changingPassword,
    bool? showPasswordSection,
    bool? changingEmail,
    bool? showEmailSection,
    bool clearUser = false,
  }) {
    return ProfileState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: error,
      editing: editing ?? this.editing,
      saving: saving ?? this.saving,
      changingPassword: changingPassword ?? this.changingPassword,
      showPasswordSection: showPasswordSection ?? this.showPasswordSection,
      changingEmail: changingEmail ?? this.changingEmail,
      showEmailSection: showEmailSection ?? this.showEmailSection,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _service;

  ProfileCubit(this._service) : super(const ProfileState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final user = await _service.getProfile();
      emit(state.copyWith(user: user, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void enterEdit() => emit(state.copyWith(editing: true));
  void cancelEdit() => emit(state.copyWith(editing: false));

  Future<void> saveProfile(String firstName, String lastName, String? avatarType, String? avatarValue) async {
    emit(state.copyWith(saving: true));
    try {
      await _service.updateProfile(
        firstName: firstName,
        lastName: lastName,
        avatarType: avatarType,
        avatarValue: avatarValue,
      );
      await load();
    } catch (e) {
      emit(state.copyWith(saving: false));
      rethrow;
    }
  }

  Future<dynamic> changePassword(String currentPassword, String newPassword) async {
    emit(state.copyWith(changingPassword: true));
    try {
      final msg = await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(state.copyWith(changingPassword: false));
      return msg;
    } catch (e) {
      emit(state.copyWith(changingPassword: false));
      rethrow;
    }
  }

  Future<dynamic> requestEmailChange(String currentPassword, String newEmail) async {
    emit(state.copyWith(changingEmail: true));
    try {
      final data = await _service.requestEmailChange(
        currentPassword: currentPassword,
        newEmail: newEmail,
      );
      emit(state.copyWith(changingEmail: false));
      return data;
    } catch (e) {
      emit(state.copyWith(changingEmail: false));
      rethrow;
    }
  }

  Future<dynamic> verifyNewEmail(String token) async {
    final msg = await _service.verifyNewEmail(token: token);
    return msg;
  }

  Future<void> selectBadge(String slug) async {
    await _service.selectBadge(slug);
    await load();
  }

  void togglePasswordSection() => emit(state.copyWith(showPasswordSection: !state.showPasswordSection));
  void toggleEmailSection() => emit(state.copyWith(showEmailSection: !state.showEmailSection));
}
