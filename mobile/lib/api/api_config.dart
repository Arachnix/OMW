import 'package:flutter/foundation.dart';

/// Where the OMW backend (`npm start` in the repo root, port 3033) lives.
///
/// Override at build time:
///   flutter run --dart-define=OMW_API_URL=http://192.168.1.20:3033
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('OMW_API_URL');
  static const int defaultPort = 3033;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:$defaultPort';
    }
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$defaultPort';
    }
    return 'http://localhost:$defaultPort';
  }

  static Uri get socketUrl {
    final base = Uri.parse(baseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws',
    );
  }
}
