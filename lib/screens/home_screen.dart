import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<VpnProvider>(
          builder: (ctx, vpn, _) => Column(
            children: [
              _Header(),
              const SizedBox(height: 8),
              _ConnectPanel(vpn: vpn),
              const SizedBox(height: 20),
              Expanded(child: _ServerList(vpn: vpn)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sports_soccer, color: Colors.white70),
            onPressed: () {},
          ),
          const Expanded(
            child: Center(
              child: Text(
                'VPN',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Connect panel ─────────────────────────────────────────────────────────────
class _ConnectPanel extends StatelessWidget {
  final VpnProvider vpn;
  const _ConnectPanel({required this.vpn});

  @override
  Widget build(BuildContext context) {
    final connected = vpn.status == VpnStatus.connected;
    final connecting = vpn.status == VpnStatus.connecting;

    return Column(
      children: [
        Text(
          'Время подключения',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          connected ? vpn.elapsedString : '--:--',
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),

        // Big button
        GestureDetector(
          onTap: vpn.toggle,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: connecting
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 3),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      connected ? Icons.stop : Icons.play_arrow,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                connected
                    ? 'Подключено'
                    : connecting
                        ? 'Подключение...'
                        : 'Отключено',
                style: TextStyle(
                  color: connected ? AppTheme.accent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (connected)
                const Icon(Icons.chevron_right, color: AppTheme.accent, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Server list ───────────────────────────────────────────────────────────────
class _ServerList extends StatelessWidget {
  final VpnProvider vpn;
  const _ServerList({required this.vpn});

  @override
  Widget build(BuildContext context) {
    if (vpn.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    if (vpn.subscriptionUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            const Text('Добавьте URL подписки в настройках',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: const Text('Настройки',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (vpn.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 8),
            Text(vpn.error!, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: vpn.refresh,
              child: const Text('Повторить', style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (vpn.whitelistServers.isNotEmpty) ...[
          _CategoryHeader(title: 'Белый список'),
          _ServerGroup(servers: vpn.whitelistServers, vpn: vpn),
          const SizedBox(height: 16),
        ],
        if (vpn.mainServers.isNotEmpty) ...[
          _CategoryHeader(title: 'Основные'),
          _ServerGroup(servers: vpn.mainServers, vpn: vpn),
          const SizedBox(height: 16),
        ],
        if (vpn.backupServers.isNotEmpty) ...[
          _CategoryHeader(title: 'Резервные'),
          _ServerGroup(servers: vpn.backupServers, vpn: vpn),
        ],
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          const Icon(Icons.speed, color: Colors.white38, size: 17),
        ],
      ),
    );
  }
}

class _ServerGroup extends StatelessWidget {
  final List<Server> servers;
  final VpnProvider vpn;
  const _ServerGroup({required this.servers, required this.vpn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(servers.length, (i) {
          final s = servers[i];
          final last = i == servers.length - 1;
          return _ServerTile(server: s, vpn: vpn, isLast: last);
        }),
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  final Server server;
  final VpnProvider vpn;
  final bool isLast;
  const _ServerTile({required this.server, required this.vpn, required this.isLast});

  Color _pingColor(int ms) {
    if (ms < 150) return AppTheme.accent;
    if (ms < 300) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(server == vpn.mainServers.firstOrNull ? 16 : 0),
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      onTap: () => vpn.selectServer(server),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom:
                      BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            Text(server.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(server.countryName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  if (server.city.isNotEmpty)
                    Text(
                      '${server.city}  (${server.tag})',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (server.pingMs != null) ...[
              Text('${server.pingMs}ms',
                  style: TextStyle(
                      color: _pingColor(server.pingMs!),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
            ],
            if (server.isSelected)
              const Icon(Icons.check, color: AppTheme.accent, size: 18),
          ],
        ),
      ),
    );
  }
}
