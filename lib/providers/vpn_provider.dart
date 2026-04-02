import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server.dart';
import '../services/subscription_service.dart';
import '../services/ping_service.dart';

enum VpnStatus { disconnected, connecting, connected }

class VpnProvider extends ChangeNotifier {
  List<Server> _servers = [];
  Server? _selectedServer;
  VpnStatus _status = VpnStatus.disconnected;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _loading = false;
  String? _error;
  String? _subscriptionUrl;
  bool _connectOnStart = true;
  bool _vibration = true;

  late FlutterV2ray _v2ray;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<Server> get whitelistServers =>
      _servers.where((s) => s.category == ServerCategory.whitelist).toList();
  List<Server> get mainServers =>
      _servers.where((s) => s.category == ServerCategory.main).toList();
  List<Server> get backupServers =>
      _servers.where((s) => s.category == ServerCategory.backup).toList();

  Server? get selectedServer => _selectedServer;
  VpnStatus get status => _status;
  bool get loading => _loading;
  String? get error => _error;
  String? get subscriptionUrl => _subscriptionUrl;
  bool get connectOnStart => _connectOnStart;
  bool get vibration => _vibration;

  String get elapsedString {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return _elapsed.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _v2ray = FlutterV2ray(onStatusChanged: _onStatus);
    await _v2ray.initializeV2Ray();

    final prefs = await SharedPreferences.getInstance();
    _subscriptionUrl = prefs.getString('sub_url');
    _connectOnStart = prefs.getBool('connect_on_start') ?? true;
    _vibration = prefs.getBool('vibration') ?? true;

    if (_subscriptionUrl != null) await refresh();
    if (_connectOnStart && _selectedServer != null) await connect();
  }

  // ── Status handler ─────────────────────────────────────────────────────────
  void _onStatus(V2RayStatus s) {
    switch (s.state) {
      case 'CONNECTED':
        _status = VpnStatus.connected;
        _startTimer();
      case 'DISCONNECTED':
        _status = VpnStatus.disconnected;
        _stopTimer();
      case 'CONNECTING':
        _status = VpnStatus.connecting;
    }
    notifyListeners();
  }

  void _startTimer() {
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _elapsed = Duration.zero;
    notifyListeners();
  }

  // ── Subscription ───────────────────────────────────────────────────────────
  Future<void> refresh() async {
    if (_subscriptionUrl == null) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _servers = await SubscriptionService.fetch(_subscriptionUrl!);

      // Auto-select first main server
      if (_selectedServer == null && mainServers.isNotEmpty) {
        _selectedServer = mainServers.first..isSelected = true;
      }

      _pingAll(); // fire and forget
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _pingAll() async {
    for (final s in _servers) {
      s.pingMs = await PingService.measure(s.url);
      notifyListeners();
    }
  }

  Future<void> setSubscriptionUrl(String url) async {
    _subscriptionUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sub_url', _subscriptionUrl!);
    await refresh();
  }

  // ── Server selection ───────────────────────────────────────────────────────
  void selectServer(Server server) {
    _selectedServer?.isSelected = false;
    _selectedServer = server..isSelected = true;
    notifyListeners();
  }

  // ── Connection ─────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_selectedServer == null) return;
    final ok = await _v2ray.requestPermission();
    if (!ok) return;

    _status = VpnStatus.connecting;
    notifyListeners();

    try {
      final parsed = FlutterV2ray.parseFromURL(_selectedServer!.url);
      await _v2ray.startV2Ray(
        remark: _selectedServer!.remark,
        config: parsed.getFullConfiguration(),
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
      );
    } catch (e) {
      _status = VpnStatus.disconnected;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> disconnect() => _v2ray.stopV2Ray();

  Future<void> toggle() async {
    if (_status == VpnStatus.disconnected) {
      await connect();
    } else {
      await disconnect();
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  Future<void> setConnectOnStart(bool v) async {
    _connectOnStart = v;
    (await SharedPreferences.getInstance()).setBool('connect_on_start', v);
    notifyListeners();
  }

  Future<void> setVibration(bool v) async {
    _vibration = v;
    (await SharedPreferences.getInstance()).setBool('vibration', v);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
