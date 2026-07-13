import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Tracks whether the device currently has working internet access.
///
/// [connectivity_plus] only reports the active network interface (wifi/mobile),
/// not whether the internet is actually reachable. So after detecting an
/// interface we confirm reachability with a tiny HTTP request. On web we trust
/// the interface status only (no cross-origin reachability probe).
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// `true` when the device is believed to be online. Starts optimistic so the
  /// first frame never flashes the offline screen before the initial check.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _initialized = false;
  bool _checking = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleResults,
      onError: (_) => isOnline.value = true,
    );

    try {
      final results = await _connectivity.checkConnectivity();
      await _handleResults(results);
    } catch (_) {
      isOnline.value = true;
    }
  }

  Future<void> _handleResults(List<ConnectivityResult> results) async {
    final hasInterface =
        results.any((result) => result != ConnectivityResult.none);

    if (!hasInterface) {
      isOnline.value = false;
      return;
    }

    if (kIsWeb) {
      isOnline.value = true;
      return;
    }

    isOnline.value = await _hasRealInternet();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Re-runs the connectivity check on demand (used by the "Try again" button).
  Future<bool> recheck() async {
    if (_checking) return isOnline.value;
    _checking = true;
    try {
      final results = await _connectivity.checkConnectivity();
      await _handleResults(results);
    } catch (_) {
      // Keep the last known value on failure.
    } finally {
      _checking = false;
    }
    return isOnline.value;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
