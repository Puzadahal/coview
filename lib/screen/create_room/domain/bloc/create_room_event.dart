import 'package:equatable/equatable.dart';

abstract class CreateRoomEvent extends Equatable {
  const CreateRoomEvent();

  @override
  List<Object> get props => [];
}

class RoomNameChanged extends CreateRoomEvent {
  final String name;

  const RoomNameChanged(this.name);

  @override
  List<Object> get props => [name];
}

class VideoUrlChanged extends CreateRoomEvent {
  final String url;

  const VideoUrlChanged(this.url);

  @override
  List<Object> get props => [url];
}

class PrivacySettingChanged extends CreateRoomEvent {
  final bool isPrivate;

  const PrivacySettingChanged(this.isPrivate);

  @override
  List<Object> get props => [isPrivate];
}

class HostControlsOnlyChanged extends CreateRoomEvent {
  final bool hostControlsOnly;

  const HostControlsOnlyChanged(this.hostControlsOnly);

  @override
  List<Object> get props => [hostControlsOnly];
}

class ParticipantLimitChanged extends CreateRoomEvent {
  final int limit;

  const ParticipantLimitChanged(this.limit);

  @override
  List<Object> get props => [limit];
}

class TextChatEnabledChanged extends CreateRoomEvent {
  final bool enabled;

  const TextChatEnabledChanged(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class VoiceChatEnabledChanged extends CreateRoomEvent {
  final bool enabled;

  const VoiceChatEnabledChanged(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class VideoBubblesEnabledChanged extends CreateRoomEvent {
  final bool enabled;

  const VideoBubblesEnabledChanged(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class AdvancedSettingsToggled extends CreateRoomEvent {
  final bool isExpanded;

  const AdvancedSettingsToggled(this.isExpanded);

  @override
  List<Object> get props => [isExpanded];
}

class CreateRoomButtonPressed extends CreateRoomEvent {
  const CreateRoomButtonPressed();
}

class CreateRoomFormReset extends CreateRoomEvent {
  const CreateRoomFormReset();
}
