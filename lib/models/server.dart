enum ServerCategory { whitelist, main, backup }

class Server {
  final String url;
  final String remark;
  final String countryCode;
  final String countryName;
  final String city;
  final String tag;
  final ServerCategory category;
  int? pingMs;
  bool isSelected;

  Server({
    required this.url,
    required this.remark,
    required this.countryCode,
    required this.countryName,
    required this.city,
    required this.tag,
    required this.category,
    this.pingMs,
    this.isSelected = false,
  });

  static const Map<String, String> _countryNames = {
    'RU': 'Россия',
    'NL': 'Нидерланды',
    'FI': 'Финляндия',
    'DE': 'Германия',
    'SE': 'Швеция',
    'PL': 'Польша',
    'TR': 'Турция',
    'BR': 'Бразилия',
    'JP': 'Япония',
    'FR': 'Франция',
    'US': 'США',
    'GB': 'Великобритания',
    'UA': 'Украина',
    'KZ': 'Казахстан',
  };

  static const Map<String, String> _cityNames = {
    'LED': 'Санкт-Петербург',
    'MOW': 'Москва',
    'AMS': 'Амстердам',
    'HEL': 'Хельсинки',
    'FRA': 'Франкфурт',
    'ARN': 'Стокгольм',
    'WAW': 'Варшава',
    'IST': 'Стамбул',
    'GRU': 'Сан-Паулу',
    'NRT': 'Токио',
    'CDG': 'Париж',
    'LAX': 'Лос-Анджелес',
    'LHR': 'Лондон',
  };

  static String flagEmoji(String code) {
    if (code.length != 2) return '🌐';
    final a = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final b = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(a) + String.fromCharCode(b);
  }

  /// Categorize by remark text:
  /// Contains "WL" → whitelist (bypass RKN)
  /// Contains "RR" → backup
  /// Otherwise     → main VPN
  static ServerCategory _categorize(String remark) {
    final upper = remark.toUpperCase();
    if (upper.contains('WL')) return ServerCategory.whitelist;
    if (upper.contains('RR')) return ServerCategory.backup;
    return ServerCategory.main;
  }

  static String _resolveCity(String raw) {
    final upper = raw.toUpperCase();
    for (final entry in _cityNames.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return raw;
  }

  factory Server.fromUrl(String url) {
    try {
      final remarkEncoded = url.contains('#') ? url.split('#').last : '';
      final remark = Uri.decodeComponent(remarkEncoded);
      final category = _categorize(remark);

      // Remark format: "RUWL 1, LEDWL" or "NL 6, AMS" or "SERR 1, ARNRR"
      // Country code = first 2 uppercase alpha characters
      final parts = remark.split(',');
      final firstPart = parts.first.trim(); // e.g. "RUWL 1" or "NL 6"

      final countryMatch = RegExp(r'^([A-Za-z]{2})').firstMatch(firstPart);
      final countryCode = countryMatch?.group(1)?.toUpperCase() ?? 'XX';
      final countryName = _countryNames[countryCode] ?? countryCode;

      // City code = first 3 alpha characters of second comma-separated part
      String city = '';
      if (parts.length > 1) {
        final secondPart = parts[1].trim(); // e.g. "LEDWL" or "AMS"
        final cityMatch = RegExp(r'^([A-Za-z]{3})').firstMatch(secondPart);
        final cityCode = cityMatch?.group(1)?.toUpperCase() ?? '';
        city = _resolveCity(cityCode);
      }

      return Server(
        url: url,
        remark: remark,
        countryCode: countryCode,
        countryName: countryName,
        city: city,
        tag: remark,
        category: category,
      );
    } catch (_) {
      return Server(
        url: url,
        remark: url,
        countryCode: 'XX',
        countryName: 'Unknown',
        city: '',
        tag: url,
        category: ServerCategory.main,
      );
    }
  }

  String get flag => flagEmoji(countryCode);
}
