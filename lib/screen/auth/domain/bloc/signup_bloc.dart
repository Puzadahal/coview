import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coview/screen/auth/data/auth_methods.dart';

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
      _onConfirmPasswordVisibilityToggled,
    );
    on<SignupAgreedToTermsChanged>(_onAgreedToTermsChanged);
    on<SignupEmailFieldFocused>(_onFieldFocused);
    on<SignupPasswordFieldFocused>(_onFieldFocused);
    on<SignupFieldUnfocused>(_onFieldUnfocused);
    on<SignupButtonPressed>(_onSignupButtonPressed);
  }

  final AuthMethods _authMethods = AuthMethods();

  void _onAgreedToTermsChanged(
    SignupAgreedToTermsChanged event,
    Emitter<SignupState> emit,
  ) {
    emit(state.copyWith(agreedToTerms: event.value));
  }

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void _onFieldFocused(SignupEvent event, Emitter<SignupState> emit) {
    emit(
      state.copyWith(
        status: SignupStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onFieldUnfocused(SignupFieldUnfocused event, Emitter<SignupState> emit) {}

  void _onNameChanged(SignupNameChanged event, Emitter<SignupState> emit) {
    emit(
      state.copyWith(
        name: event.value,
        status: SignupStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onEmailChanged(SignupEmailChanged event, Emitter<SignupState> emit) {
    final isValid = _emailRegex.hasMatch(event.value);
    emit(
      state.copyWith(
        email: event.value,
        isEmailValid: isValid,
        status: SignupStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onPasswordChanged(
    SignupPasswordChanged event,
    Emitter<SignupState> emit,
  ) {
    emit(
      state.copyWith(
        password: event.value,
        status: SignupStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onConfirmPasswordChanged(
    SignupConfirmPasswordChanged event,
    Emitter<SignupState> emit,
  ) {
    emit(
      state.copyWith(
        confirmPassword: event.value,
        status: SignupStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    SignupPasswordVisibilityToggled event,
    Emitter<SignupState> emit,
  ) {
    emit(
      state.copyWith(
        isPasswordVisible: !state.isPasswordVisible,
      ),
    );
  }

  void _onConfirmPasswordVisibilityToggled(
    SignupConfirmPasswordVisibilityToggled event,
    Emitter<SignupState> emit,
  ) {
    emit(
      state.copyWith(
        isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
      ),
    );
  }

  Future<void> _onSignupButtonPressed(
    SignupButtonPressed event,
    Emitter<SignupState> emit,
  ) async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: 'Please fill all fields correctly.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SignupStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      await _authMethods.signUpWithEmail(
        name: state.name.trim(),
        email: state.email.trim(),
        password: state.password,
      );
      emit(
        state.copyWith(
          status: SignupStatus.success,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}

