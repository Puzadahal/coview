import 'package:equatable/equatable.dart';

enum HomeStatus { initial, loading, loaded }

class HomeState extends Equatable {
  const HomeState({this.status = HomeStatus.initial});

  final HomeStatus status;

  HomeState copyWith({HomeStatus? status}) {
    return HomeState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
