/// WebRTC ICE / TURN configuration.
///
/// Optional: copy [webrtc_ice_config.example.dart] to `webrtc_ice_config.dart`
/// and add your own TURN credentials for better call reliability.
library;

import 'webrtc_ice_config.local.dart' as local;

class WebRtcIceConfig {
  WebRtcIceConfig._();

  /// Public STUN + free relay servers. Add custom TURN in [webrtc_ice_config.local.dart].
  static List<Map<String, dynamic>> get iceServers {
    final servers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
          'turns:openrelay.metered.ca:443',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': [
          'turn:global.relay.metered.ca:80',
          'turn:global.relay.metered.ca:443',
          'turn:global.relay.metered.ca:443?transport=tcp',
          'turns:global.relay.metered.ca:443',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ];

    final extra = local.extraIceServers;
    if (extra.isNotEmpty) {
      servers.insertAll(0, extra);
    }
    return servers;
  }
}
