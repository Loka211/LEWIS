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
  /// Contains "Белый список" → whitelist (bypass RKN)
  /// Contains "Резерв"      → backup
  /// Otherwise              → main VPN
  static ServerCategory _categorize(String remark) {
    if (remark.contains('Белый список')) return ServerCategory.whitelist;
    if (remark.contains('Резерв')) return ServerCategory.backup;
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

      // Remark format: "🇳🇱 Нидерланды 6" or "🇷🇺 Россия (Белый список) 1"
      // Strip flag emoji (first 2 chars if they are regional indicator symbols)
      final stripped = remark.replaceFirst(
          RegExp(r'^[\u{1F1E0}-\u{1F1FF}]{2}\s*', unicode: true), '').trim();

      // Country name = first word(s) before a digit or '('
      final match = RegExp(r'^([А-Яа-яЁё\s]+?)(?:\s+[\d(]|$)').firstMatch(stripped);
      final countryName = match?.group(1)?.trim() ?? stripped;

      // Find country code from name mapping (reverse lookup)
      String countryCode = 'XX';
      for (final e in _countryNames.entries) {
        if (e.value == countryName) {
          countryCode = e.key;
          break;
        }
      }

      // Tag = full remark cleaned of category label
      final tag = remark
          .replaceAll('(Белый список)', '')
          .replaceAll('(Резерв)', '')
          .trim();

      return Server(
        url: url,
        remark: remark,
        countryCode: countryCode,
        countryName: countryName,
        city: '',   // not in remark, extracted from hostname if needed
        tag: tag,
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
