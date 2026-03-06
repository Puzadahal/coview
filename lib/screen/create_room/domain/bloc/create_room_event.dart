import 'package:equatable/equatable.dart';

/// Events for Create Room BLoC
abstract class CreateRoomEvent extends Equatable {
  const CreateRoomEvent();

  @override
  List<Object> get props => [];
}

/// Room name changed event
class RoomNameChanged extends CreateRoomEvent {
  final String name;

  const RoomNameChanged(this.name);

  @override
  List<Object> get props => [name];
}

/// Video URL changed event
class VideoUrlChanged extends CreateRoomEvent {
  final String url;

  const VideoUrlChanged(this.url);

  @override
  List<Object> get props => [url];
}

/// Privacy setting changed event
class PrivacySettingChanged extends CreateRoomEvent {
  final bool isPrivate;

  const PrivacySettingChanged(this.isPrivate);

  @override
  List<Object> get props => [isPrivate];
}

/// Host controls only changed event
class HostControlsOnlyChanged extends CreateRoomEvent {
  final bool hostControlsOnly;

  const HostControlsOnlyChanged(this.hostControlsOnly);

  @override
  List<Object> get props => [hostControlsOnly];
}

/// Participant limit changed event
class ParticipantLimitChanged extends CreateRoomEvent {
  final int limit;

  const ParticipantLimitChanged(this.limit);

  @override
  List<Object> get props => [limit];
}

/// Text chat enabled changed event
class TextChatEnabledChanged extends CreateRoomEvent {
  final bool enabled;

  const TextChatEnabledChanged(this.enabled);

  @override
  List<Object> get props => [enabled];
}

/// Voice chat enabled changed event
class VoiceChatEnabledChanged extends CreateRoomEvent {
  final bool enabled;

  const VoiceChatEnabledChanged(this.enabled);

  @override
  List<Object> get props => [enabled];
}

/// Video bubbles enabled changed event
class VideoBubblesEnabledChanged extends CreateRoomEvent {
  final bool enabled;

  const VideoBubblesEnabledChanged(this.enabled);

  @override
  List<Object> get props => [enabled];
}

/// Advanced settings toggled event
class AdvancedSettingsToggled extends CreateRoomEvent {
  final bool isExpanded;

  const AdvancedSettingsToggled(this.isExpanded);

  @override
  List<Object> get props => [isExpanded];
}

/// Create room button pressed event
class CreateRoomButtonPressed extends CreateRoomEvent {
  const CreateRoomButtonPressed();
}

/// Reset form event
class CreateRoomFormReset extends CreateRoomEvent {
  const CreateRoomFormReset();
}
