import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coview/screen/auth/data/auth_methods.dart';
import '../../../../core/models/user_model.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<LoginInitialized>(_onInitialized);
    on<EmailFieldFocused>(_onFieldFocused);
    on<PasswordFieldFocused>(_onFieldFocused);
    on<FieldUnfocused>(_onFieldUnfocused);
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<RememberMeChanged>(_onRememberMeChanged);
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<GuestLoginRequested>(_onGuestLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    add(const LoginInitialized());
  }

  final AuthMethods _authMethods = AuthMethods();


  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const _prefsRememberKey = 'login_remember_me';
  static const _prefsEmailKey = 'login_saved_email';
  static const _prefsLoggedInKey = 'logged_in';

  void _onFieldFocused(LoginEvent event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        status: LoginStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onFieldUnfocused(FieldUnfocused event, Emitter<LoginState> emit) {}

  Future<void> _onInitialized(
    LoginInitialized event,
    Emitter<LoginState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefsRememberKey) ?? false;
      final savedEmail = prefs.getString(_prefsEmailKey) ?? '';
      final isValid = _emailRegex.hasMatch(savedEmail);
      emit(
        state.copyWith(
          email: remember ? savedEmail : state.email,
          isEmailValid: remember ? isValid : state.isEmailValid,
          rememberMe: remember,
        ),
      );
    } catch (_) {}
  }

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
    _persistRememberMe(event.value, state.email);
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
      final user = await _authMethods.signInWithEmail(
        email: state.email,
        password: state.password,
      );

      await _persistRememberMe(state.rememberMe, state.email);
      await _persistLoggedIn(true);

      emit(
        state.copyWith(
          status: LoginStatus.success,
          user: user,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onGuestLoginRequested(
    GuestLoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading));
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(10000);
      final guestId = 'guest_${timestamp}_$random';

      final guestUser = User.guest(guestId);

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
        await _persistLoggedIn(true);
        emit(
          state.copyWith(
            status: LoginStatus.success,
            user: user,
            errorMessage: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'Google sign-in cancelled',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _persistRememberMe(bool remember, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsRememberKey, remember);
      if (remember) {
        await prefs.setString(_prefsEmailKey, email);
      } else {
        await prefs.remove(_prefsEmailKey);
      }
    } catch (_) {}
  }

  Future<void> _persistLoggedIn(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsLoggedInKey, value);
    } catch (_) {}
  }
}

