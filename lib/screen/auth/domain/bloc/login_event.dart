import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginInitialized extends LoginEvent {
  const LoginInitialized();
}

class EmailChanged extends LoginEvent {
  final String value;

  const EmailChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class PasswordChanged extends LoginEvent {
  final String value;

  const PasswordChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class EmailFieldFocused extends LoginEvent {
  const EmailFieldFocused();
}

class PasswordFieldFocused extends LoginEvent {
  const PasswordFieldFocused();
}

class FieldUnfocused extends LoginEvent {
  const FieldUnfocused();
}

class PasswordVisibilityToggled extends LoginEvent {
  const PasswordVisibilityToggled();
}

class RememberMeChanged extends LoginEvent {
  final bool value;

  const RememberMeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class LoginButtonPressed extends LoginEvent {
  const LoginButtonPressed();
}

/// Guest login requested event - user wants to join as guest
class GuestLoginRequested extends LoginEvent {
  const GuestLoginRequested();
}
  


  class GoogleLoginRequested extends LoginEvent {
  const GoogleLoginRequested();
}
