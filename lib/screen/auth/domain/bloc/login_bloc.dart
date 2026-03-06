import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coview/screen/auth/data/auth_methods.dart';
import '../../../../core/models/user_model.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<RememberMeChanged>(_onRememberMeChanged);
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<GuestLoginRequested>(_onGuestLoginRequested);
      on<GoogleLoginRequested>(_onGoogleLoginRequested);
  }
  final AuthMethods _authMethods = AuthMethods();


  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void _onEmailChanged(EmailChanged event, Emitter<LoginState> emit) {
    final isValid = _emailRegex.hasMatch(event.value);
    emit(state.copyWith(
      email: event.value,
      isEmailValid: isValid,
      status: LoginStatus.initial,
      errorMessage: null,
    ));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      password: event.value,
      status: LoginStatus.initial,
      errorMessage: null,
    ));
  }

  void _onPasswordVisibilityToggled(
    PasswordVisibilityToggled event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  void _onRememberMeChanged(RememberMeChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(rememberMe: event.value));
  }

  void _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isFormValid) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Please enter valid email and password',
      ));
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading));
    
    try {
      // TODO: Replace with real auth (e.g. Firebase, API)
      await Future<void>.delayed(const Duration(seconds: 1));
      
      // Simulate successful login - create registered user
      final user = User.registered(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: state.email,
        name: state.email.split('@').first,
      );
      
      emit(state.copyWith(
        status: LoginStatus.success,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onGuestLoginRequested(
    GuestLoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading));
    
    try {
      // Generate unique guest session ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(10000);
      final guestId = 'guest_${timestamp}_$random';
      
      // Create guest user
      final guestUser = User.guest(guestId);
      
      // Small delay for UX
      await Future<void>.delayed(const Duration(milliseconds: 500));
      
      emit(state.copyWith(
        status: LoginStatus.guestSuccess,
        user: guestUser,
        guestSessionId: guestId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Failed to create guest session',
      ));
    }
  }
  Future<void> _onGoogleLoginRequested(
  GoogleLoginRequested event,
  Emitter<LoginState> emit,
) async {
  emit(state.copyWith(status: LoginStatus.loading));

  try {
    final user = await _authMethods.signInWithGoogle();

    if (user != null) {
      emit(state.copyWith(
        status: LoginStatus.success,
        user: user,
      ));
    } else {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: "Google sign in cancelled",
      ));
    }
  } catch (e) {
    emit(state.copyWith(
      status: LoginStatus.failure,
      errorMessage: "Google sign in failed",
    ));
  }
}

}
