/// Pure helpers for server-anchored playback and drift correction.
///
/// The server is the source of truth for *when* a position was valid
/// (`updatedAt` / anchor time). Each client extrapolates with its NTP-aligned
/// clock so everyone converges on the same timeline.
class PlaybackSyncMath {
  PlaybackSyncMath._();

  /// Master timeline: position stored in Firestore at [anchorServerTimeMs].
  /// While [isPlaying] is true, time advances with [ntpNowMs].
  static double expectedPositionSeconds({
    required double anchorPositionSeconds,
    required bool isPlaying,
    required int anchorServerTimeMs,
    required int ntpNowMs,
  }) {
    if (!isPlaying) return anchorPositionSeconds;
    if (anchorServerTimeMs <= 0) return anchorPositionSeconds;
    final elapsedSec = (ntpNowMs - anchorServerTimeMs) / 1000.0;
    if (elapsedSec <= 0) return anchorPositionSeconds;//Prevent negative drift
    return anchorPositionSeconds + elapsedSec;
  }

  /// `diff = expected - local` → positive means local is *behind* (catch up).
  static DriftDecision driftDecision({
    required double expectedSeconds,
    required double localSeconds,
  }) {
    final diff = expectedSeconds - localSeconds;
    final ad = diff.abs();
    const hardSeek = 2.0;
    const softBand = 0.35;
    
    if (ad <= softBand)  return const DriftDecision.none();//If difference is tiny → do nothing.
   
    if (ad >= hardSeek) {
      return DriftDecision.hardSeek(expectedSeconds);
    }//If difference is huge → jump straight to the correct position.


    if (diff > 0) {
      return const DriftDecision.softRate(catchUp: true);//If difference is medium (0.35 < ad < 2.0) and local is behind → play slightly faster to catch up.
    }
    return const DriftDecision.softRate(catchUp: false);//If difference is medium and local is ahead → play slightly slower to let the server catch up.
  }
}

/// What to do on this drift tick (file-based [VideoPlayer] only).
class DriftDecision {
  final DriftKind kind;
  final double? seekToSeconds;
  final bool catchUp;

  const DriftDecision.none()
    : kind = DriftKind.none,
      seekToSeconds = null,
      catchUp = false;

  const DriftDecision.hardSeek(double seconds)
    : kind = DriftKind.hardSeek,
      seekToSeconds = seconds,
      catchUp = false;

  const DriftDecision.softRate({required this.catchUp})
    : kind = DriftKind.softRate,
      seekToSeconds = null;
}

enum DriftKind { none, softRate, hardSeek }
