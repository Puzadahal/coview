import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeInitialized>(_onHomeInitialized);
    on<VideoLoaded>(_onVideoLoaded);
    on<VideoError>(_onVideoError);
    on<CreateRoomPressed>(_onCreateRoomPressed);
    on<JoinRoomPressed>(_onJoinRoomPressed);
  }

  void _onHomeInitialized(HomeInitialized event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: HomeStatus.loading));
  }

  void _onVideoLoaded(VideoLoaded event, Emitter<HomeState> emit) {
    emit(state.copyWith(
      status: HomeStatus.loaded,
      isVideoLoaded: true,
      videoError: null,
    ));
  }

  void _onVideoError(VideoError event, Emitter<HomeState> emit) {
    emit(state.copyWith(
      status: HomeStatus.error,
      isVideoLoaded: false,
      videoError: event.error,
    ));
  }

  void _onCreateRoomPressed(CreateRoomPressed event, Emitter<HomeState> emit) {
    // TODO: Navigate to create room screen
  }

  void _onJoinRoomPressed(JoinRoomPressed event, Emitter<HomeState> emit) {
    // TODO: Navigate to join room screen
  }
}
