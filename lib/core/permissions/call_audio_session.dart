import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Routes call audio to the loudspeaker and applies mobile-friendly settings.
class CallAudioSession {
  static Future<void> activate() async {
    try {
      await Helper.setSpeakerphoneOn(true);
      if (WebRTC.platformIsAndroid) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration(
            androidAudioMode: AndroidAudioMode.inCommunication,
            androidAudioStreamType: AndroidAudioStreamType.voiceCall,
            androidAudioAttributesUsageType:
                AndroidAudioAttributesUsageType.voiceCommunication,
            androidAudioAttributesContentType:
                AndroidAudioAttributesContentType.speech,
          ),
        );
      }
    } catch (e) {
      debugPrint('CallAudioSession: activate failed: $e');
    }
  }

  static Future<void> deactivate() async {
    try {
      await Helper.setSpeakerphoneOn(false);
    } catch (e) {
      debugPrint('CallAudioSession: deactivate failed: $e');
    }
  }
}
