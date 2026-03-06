import 'package:equatable/equatable.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

class SignupNameChanged extends SignupEvent {
  final String value;

  const SignupNameChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class SignupEmailChanged extends SignupEvent {
  final String value;

  const SignupEmailChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class SignupPasswordChanged extends SignupEvent {
  final String value;

  const SignupPasswordChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class SignupConfirmPasswordChanged extends SignupEvent {
  final String value;

  const SignupConfirmPasswordChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class SignupEmailFieldFocused extends SignupEvent {
  const SignupEmailFieldFocused();
}

class SignupPasswordFieldFocused extends SignupEvent {
  const SignupPasswordFieldFocused();
}

class SignupFieldUnfocused extends SignupEvent {
  const SignupFieldUnfocused();
}

class SignupPasswordVisibilityToggled extends SignupEvent {
  const SignupPasswordVisibilityToggled();
}

class SignupConfirmPasswordVisibilityToggled extends SignupEvent {
  const SignupConfirmPasswordVisibilityToggled();
}

class SignupAgreedToTermsChanged extends SignupEvent {
  final bool value;

  const SignupAgreedToTermsChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class SignupButtonPressed extends SignupEvent {
  const SignupButtonPressed();
}
