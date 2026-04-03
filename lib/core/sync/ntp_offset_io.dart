import 'package:ntp/ntp.dart';

/// Resolves clock offset vs NTP (UDP). Only compiled on io platforms.
Future<int> loadNtpOffsetMilliseconds() async {
  try {
    return await NTP.getNtpOffset(
      timeout: const Duration(seconds: 5),
    );
  } catch (_) {
    return 0;
  }
}
