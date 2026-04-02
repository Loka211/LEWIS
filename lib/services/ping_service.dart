import 'dart:io';

class PingService {
  static Future<int?> measure(String url) async {
    final host = _host(url);
    final port = _port(url);
    if (host == null || port == null) return null;
    try {
      final sw = Stopwatch()..start();
      final sock = await Socket.connect(host, port,
          timeout: const Duration(seconds: 3));
      sw.stop();
      sock.destroy();
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  static String? _host(String url) {
    try {
      final at = url.indexOf('@');
      if (at == -1) return null;
      final after = url.substring(at + 1);
      final colon = after.indexOf(':');
      if (colon == -1) return null;
      return after.substring(0, colon);
    } catch (_) {
      return null;
    }
  }

  static int? _port(String url) {
    try {
      final at = url.indexOf('@');
      if (at == -1) return null;
      final after = url.substring(at + 1);
      final colon = after.indexOf(':');
      if (colon == -1) return null;
      final portStr =
          after.substring(colon + 1).split('?').first.split('#').first;
      return int.tryParse(portStr);
    } catch (_) {
      return null;
    }
  }
}
