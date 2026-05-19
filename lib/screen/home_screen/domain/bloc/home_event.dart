import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeInitialized extends HomeEvent {
  const HomeInitialized();
}

class VideoLoaded extends HomeEvent {
  const VideoLoaded();
}

class VideoError extends HomeEvent {
  final String error;

  const VideoError(this.error);

  @override
  List<Object?> get props => [error];
}
