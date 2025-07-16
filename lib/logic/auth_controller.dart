import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/user.dart';

part 'auth_controller.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.success(AppUser user) = _Success;
  const factory AuthState.failure(String error) = _Failure;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.initial());

  // Add authentication logic here (register, login, etc.)
}
