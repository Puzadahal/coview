import 'package:equatable/equatable.dart';

abstract class JoinRoomEvent extends Equatable {
  const JoinRoomEvent();

  @override
  List<Object?> get props => [];
}

class JoinRoomInputChanged extends JoinRoomEvent {
  final String value;

  const JoinRoomInputChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class JoinRoomSubmitted extends JoinRoomEvent {
  const JoinRoomSubmitted();
}

