import 'package:equatable/equatable.dart';

enum JoinRoomStatus { initial, validating, success, failure }

class JoinRoomState extends Equatable {
  final String rawInput;
  final String? error;
  final String? resolvedRoomId;
  final JoinRoomStatus status;

  const JoinRoomState({
    this.rawInput = '',
    this.error,
    this.resolvedRoomId,
    this.status = JoinRoomStatus.initial,
  });

  bool get canSubmit =>
      rawInput.trim().isNotEmpty && status != JoinRoomStatus.validating;

  bool get isValidating => status == JoinRoomStatus.validating;

  JoinRoomState copyWith({
    String? rawInput,
    String? error,
    String? resolvedRoomId,
    JoinRoomStatus? status,
  }) {
    return JoinRoomState(
      rawInput: rawInput ?? this.rawInput,
      error: error,
      resolvedRoomId: resolvedRoomId ?? this.resolvedRoomId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [rawInput, error, resolvedRoomId, status];
}

