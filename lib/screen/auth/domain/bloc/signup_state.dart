import 'package:equatable/equatable.dart';

enum SignupStatus { initial, loading, success, failure }

class SignupState extends Equatable {
  const SignupState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isEmailValid = false,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.agreedToTerms = false,
    this.status = SignupStatus.initial,
    this.errorMessage,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isEmailValid;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool agreedToTerms;
  final SignupStatus status;
  final String? errorMessage;

  bool get doPasswordsMatch =>
      password.isNotEmpty && password == confirmPassword;

  bool get isFormValid =>
      name.trim().isNotEmpty &&
      isEmailValid &&
      password.length >= 8 &&
      doPasswordsMatch &&
      agreedToTerms;

  SignupState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isEmailValid,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? agreedToTerms,
    SignupStatus? status,
    String? errorMessage,
  }) {
    return SignupState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        confirmPassword,
        isEmailValid,
        isPasswordVisible,
        isConfirmPasswordVisible,
        agreedToTerms,
        status,
        errorMessage,
      ];
}
