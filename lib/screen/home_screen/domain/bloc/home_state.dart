import 'package:equatable/equatable.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.isVideoLoaded = false,
    this.videoError,
  });

  final HomeStatus status;
  final bool isVideoLoaded;
  final String? videoError;

  HomeState copyWith({
    HomeStatus? status,
    bool? isVideoLoaded,
    String? videoError,
  }) {
    return HomeState(
      status: status ?? this.status,
      isVideoLoaded: isVideoLoaded ?? this.isVideoLoaded,
      videoError: videoError,
    );
  }

  @override
  List<Object?> get props => [status, isVideoLoaded, videoError];
}
