import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/server.dart';

class SubscriptionService {
  static Future<List<Server>> fetch(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'v2rayNG/1.8.0'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final body = response.body.trim();

    // Try base64 decode (standard subscription format)
    List<String> lines;
    try {
      final decoded = utf8.decode(base64.decode(base64.normalize(body)));
      lines = decoded.split('\n').where((l) => l.trim().isNotEmpty).toList();
    } catch (_) {
      // Plain text list
      lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    }

    return lines
        .map((l) => l.trim())
        .where((l) =>
            l.startsWith('vless://') ||
            l.startsWith('vmess://') ||
            l.startsWith('trojan://') ||
            l.startsWith('ss://'))
        .map(Server.fromUrl)
        .toList();
  }
}
