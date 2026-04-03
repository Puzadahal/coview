import 'ntp_offset_stub.dart'
    if (dart.library.io) 'ntp_offset_io.dart' as ntp_offset;

/// Shared clock aligned with NTP where possible.
///
/// **Model:** Firestore stores `updatedAt` (server UTC) and `positionSeconds`
/// at that instant. Each client computes "now" in the same UTC frame:
///
/// `ntpNowMs = DateTime.now().millisecondsSinceEpoch + offsetMs`
///
/// `offsetMs` comes from an NTP query (or 0 on web). Then elapsed playback
/// time is `(ntpNowMs - anchorServerTimeMs) / 1000` when `isPlaying` is true.
class NtpClock {
  NtpClock._();
  static final NtpClock instance = NtpClock._();

  int _offsetMs = 0;

  /// Monotonic wall clock in ms, adjusted by last NTP offset.
  int get nowMs => DateTime.now().millisecondsSinceEpoch + _offsetMs;

  /// Refresh offset from an NTP server (no-op / zero on web).
  Future<void> refresh() async {
    _offsetMs = await ntp_offset.loadNtpOffsetMilliseconds();
  }
}
