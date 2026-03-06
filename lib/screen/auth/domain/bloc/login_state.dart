import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';

enum LoginStatus { initial, loading, success, failure, guestSuccess }

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isEmailValid = false,
    this.isPasswordVisible = false,
    this.rememberMe = false,
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.user,
    this.guestSessionId,
  });

  final String email;
  final String password;
  final bool isEmailValid;
  final bool isPasswordVisible;
  final bool rememberMe;
  final LoginStatus status;
  final String? errorMessage;
  final User? user;
  final String? guestSessionId;

  bool get isFormValid => isEmailValid && password.length >= 8;
  bool get isGuestMode => user?.isGuestMode ?? false;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isEmailValid,
    bool? isPasswordVisible,
    bool? rememberMe,
    LoginStatus? status,
    String? errorMessage,
    User? user,
    String? guestSessionId,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
      guestSessionId: guestSessionId ?? this.guestSessionId,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        isEmailValid,
        isPasswordVisible,
        rememberMe,
        status,
        errorMessage,
        user,
        guestSessionId,
      ];
}
