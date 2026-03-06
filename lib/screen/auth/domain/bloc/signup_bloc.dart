import 'package:flutter_bloc/flutter_bloc.dart';

import 'signup_event.dart';
import 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(const SignupState()) {
    on<SignupNameChanged>(_onNameChanged);
    on<SignupEmailChanged>(_onEmailChanged);
    on<SignupPasswordChanged>(_onPasswordChanged);
    on<SignupConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignupPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<SignupConfirmPasswordVisibilityToggled>(
        _onConfirmPasswordVisibilityToggled);
    on<SignupAgreedToTermsChanged>(_onAgreedToTermsChanged);
    on<SignupButtonPressed>(_onSignupButtonPressed);
  }

  void _onAgreedToTermsChanged(
      SignupAgreedToTermsChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(agreedToTerms: event.value));
  }

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void _onNameChanged(SignupNameChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(
      name: event.value,
      status: SignupStatus.initial,
      errorMessage: null,
    ));
  }

  void _onEmailChanged(SignupEmailChanged event, Emitter<SignupState> emit) {
    final isValid = _emailRegex.hasMatch(event.value);
    emit(state.copyWith(
      email: event.value,
      isEmailValid: isValid,
      status: SignupStatus.initial,
      errorMessage: null,
    ));
  }

  void _onPasswordChanged(
      SignupPasswordChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(
      password: event.value,
      status: SignupStatus.initial,
      errorMessage: null,
    ));
  }

  void _onConfirmPasswordChanged(
      SignupConfirmPasswordChanged event, Emitter<SignupState> emit) {
    emit(state.copyWith(
      confirmPassword: event.value,
      status: SignupStatus.initial,
      errorMessage: null,
    ));
  }

  void _onPasswordVisibilityToggled(
    SignupPasswordVisibilityToggled event,
    Emitter<SignupState> emit,
  ) {
    emit(state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  void _onConfirmPasswordVisibilityToggled(
    SignupConfirmPasswordVisibilityToggled event,
    Emitter<SignupState> emit,
  ) {
    emit(state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    ));
  }

  void _onSignupButtonPressed(
    SignupButtonPressed event,
    Emitter<SignupState> emit,
  ) async {
    print('[SignupBloc] SignupButtonPressed event received');
    print('[SignupBloc] Current state - isFormValid: ${state.isFormValid}');
    emit(state.copyWith(status: SignupStatus.loading));
    print('[SignupBloc] Status set to loading');
    // TODO: Replace with real auth (e.g. Firebase, API)
    await Future<void>.delayed(const Duration(seconds: 1));
    print('[SignupBloc] Setting status to success');
    emit(state.copyWith(status: SignupStatus.success));
    print('[SignupBloc] Status set to success');
  }
}
