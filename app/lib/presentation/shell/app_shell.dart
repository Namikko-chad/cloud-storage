import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:window_manager/window_manager.dart';

import '../../core/config/app_config.dart';
import '../../core/desktop/desktop_window.dart';
import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../common/hm.dart';
import '../core/core_cubit.dart';
import '../files/files_screen.dart';
import '../log/log_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../secrets/secrets_screen.dart';
import '../storages/storages_screen.dart';
import '../unlock/unlock_screen.dart';
import '../vault/vault_screen.dart';

enum Section { files, secrets, storages, maintenance, log, vault }

extension on Section {
  String get label => switch (this) {
    Section.files => tr('Files', 'Файлы'),
    Section.secrets => tr('Passwords', 'Пароли'),
    Section.storages => tr('Storages', 'Хранилища'),
    Section.maintenance => tr('Maintenance', 'Обслуживание'),
    Section.log => tr('Log', 'Журнал'),
    Section.vault => 'Vault',
  };

  IconData get icon => switch (this) {
    Section.files => Icons.folder_outlined,
    Section.secrets => Icons.password_outlined,
    Section.storages => Icons.cloud_outlined,
    Section.maintenance => Icons.build_outlined,
    Section.log => Icons.receipt_long_outlined,
    Section.vault => Icons.key_outlined,
  };
}

/// The page shell (§ 2, § 4–6; MOBILITY M2, M4, M6): picks the section and
/// lays out header, canvas and footer or tab bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initial = Section.files});

  final Section initial;

  /// Phone tabs (M4.2: at most five): the log opens from the Vault screen.
  static const mobileTabs = [Section.files, Section.secrets, Section.storages, Section.maintenance, Section.vault];

  /// Opens a section.
  static void go(BuildContext context, Section s) => context.findAncestorStateOfType<_AppShellState>()?._go(s);

  /// Opens the Log section filtered to one storage.
  static void openLog(BuildContext context, String backendId) => context.findAncestorStateOfType<_AppShellState>()?._openLog(backendId);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late Section _section = widget.initial;
  String? _logFilter;

  void _openLog(String backendId) => setState(() {
    _section = Section.log;
    _logFilter = backendId;
  });

  void _go(Section s) {
    if (s != _section) HapticFeedback.selectionClick();
    setState(() {
      _section = s;
      _logFilter = null;
    });
  }

  Future<void> _lock() async {
    try {
      await context.read<CoreCubit>().lockVault();
    } catch (e) {
      Toasts.error(tr('Could not lock', 'Не удалось заблокировать'), '$e');
    }
  }

  Section _shown(bool ready) => !ready && _section != Section.vault && _section != Section.log ? Section.storages : _section;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final core = context.watch<CoreCubit>().state;
    final unlocked = core.conn == Conn.ready && core.unlocked;
    final ready = unlocked && (core.state?.ready ?? false);
    final Widget page = switch ((core.conn, unlocked)) {
      (Conn.connecting, _) when core.state == null => const HmLoading(),
      (_, false) => const UnlockScreen(),
      // Open but not working yet: storages must be added first (the log
      // tells why storages fail).
      _ when !ready && _section != Section.vault && _section != Section.log => const StoragesScreen(),
      _ => switch (_section) {
        Section.files => const FilesScreen(),
        Section.secrets => const SecretsScreen(),
        Section.storages => const StoragesScreen(),
        Section.maintenance => const MaintenanceScreen(),
        Section.log => LogScreen(key: ValueKey(_logFilter), backendId: _logFilter),
        Section.vault => VaultScreen(onLock: _lock),
      },
    };
    final body = Stack(
      children: [
        const Positioned.fill(child: _GridBackground()),
        Positioned.fill(
          child: KeyedSubtree(key: ValueKey(unlocked ? _section : 'locked'), child: page),
        ),
      ],
    );

    if (hm.mobile) {
      return Scaffold(
        backgroundColor: HmColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _MobileHeader(online: core.online),
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: unlocked
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: HmColors.border)),
                ),
                child: NavigationBar(
                  // The log is not a tab: Vault stays lit while it is open.
                  selectedIndex: AppShell.mobileTabs.indexOf(_shown(ready) == Section.log ? Section.vault : _shown(ready)),
                  onDestinationSelected: (i) => _go(AppShell.mobileTabs[i]),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final s in AppShell.mobileTabs) NavigationDestination(icon: Icon(s.icon), label: s.label, tooltip: ''),
                  ],
                ),
              )
            : null,
      );
    }
    return Scaffold(
      backgroundColor: HmColors.bezel,
      body: Container(
        margin: const EdgeInsets.all(8), // viewport bezel (§ 5.3)
        color: HmColors.bg,
        child: Column(
          children: [
            _Header(section: unlocked ? _shown(ready) : null, onGo: _go, onLock: _lock),
            Expanded(child: body),
            _Footer(core: core),
          ],
        ),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: RepaintBoundary(child: CustomPaint(painter: _GridPainter())),
  );
}

/// Fixed 40 px cyan grid at 3 % (§ 2.2); it does not scroll with content.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HmColors.tint(HmColors.accent, HmColors.subtle)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _headerGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x0A00D4FF), Color(0x0000D4FF)], // accent @ 4 % → 0
);

/// Desktop header (§ 4): logo, nav links, then the identity anchors —
/// "Vault" (the profile of this app) and "Lock" (its sign-out).
class _Header extends StatelessWidget {
  const _Header({required this.section, required this.onGo, required this.onLock});

  final Section? section;
  final ValueChanged<Section> onGo;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) => _TitleBar(
    child: Container(
      padding: const EdgeInsets.fromLTRB(32, 14, 12, 14),
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        border: Border(bottom: BorderSide(color: HmColors.border)),
      ),
      child: Row(
        children: [
          Text('CloudSync', style: HmText.logo),
          const Spacer(),
          if (section != null) ...[
            for (final s in [Section.files, Section.secrets, Section.storages, Section.maintenance, Section.log]) ...[
              _NavLink(label: s.label, active: section == s, onTap: () => onGo(s)),
              const SizedBox(width: 12),
            ],
            Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 4), color: HmColors.border),
            const SizedBox(width: 12),
            _NavLink(label: Section.vault.label, active: true, onTap: () => onGo(Section.vault)),
            const SizedBox(width: 12),
            _NavLink(label: tr('Lock', 'Заблокировать'), signOut: true, onTap: onLock),
          ],
          const SizedBox(width: 16),
          const _LangSwitch(),
          if (DesktopWindow.supported) ...[const SizedBox(width: 12), const _WindowButtons()],
        ],
      ),
    ),
  );
}

/// The app's header doubles as the window title bar on desktops: drag to
/// move, double-click to maximize.
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DesktopWindow.supported ? DragToMoveArea(child: child) : child;
}

/// EN / RU switch (the choice is kept in app settings).
class _LangSwitch extends StatelessWidget {
  const _LangSwitch();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final l in Lang.values)
        _WindowButton(
          label: l.name.toUpperCase(),
          tooltip: l == Lang.en ? 'English' : 'Русский',
          active: lang.value == l,
          onTap: () => AppSettings.instance.setLanguage(l),
        ),
    ],
  );
}

/// Minimize, maximize and close, drawn in the app's style.
class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _WindowButton(icon: Icons.remove, tooltip: tr('Minimize', 'Свернуть'), onTap: DesktopWindow.instance.minimize),
      _WindowButton(icon: Icons.crop_square, tooltip: tr('Maximize', 'Развернуть'), onTap: DesktopWindow.instance.toggleMaximize),
      _WindowButton(icon: Icons.close, tooltip: tr('Close', 'Закрыть'), danger: true, onTap: DesktopWindow.instance.close),
    ],
  );
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({required this.tooltip, required this.onTap, this.icon, this.label, this.danger = false, this.active = false});

  final IconData? icon;
  final String? label;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  final bool active;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.danger ? HmColors.error : HmColors.accent;
    final color = _hot || widget.active ? base : HmColors.muted;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.label == null ? 32 : null,
            height: 28,
            margin: const EdgeInsets.only(left: 2),
            padding: widget.label == null ? null : const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HmColors.tint(base, (_hot ? 0.12 : 0.0) + (widget.active ? 0.08 : 0.0)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.active ? HmColors.tint(base, HmColors.ring) : Colors.transparent),
            ),
            child: widget.label != null
                ? Text(widget.label!, style: HmText.nav.copyWith(color: color))
                : Icon(widget.icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap, this.active = false, this.signOut = false});

  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool signOut;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.signOut ? HmColors.error : HmColors.accent;
    final lit = widget.active || widget.signOut;
    final alpha = (lit ? 0.08 : 0.0) + (_hot ? 0.10 : 0.0);
    return Semantics(
      button: true,
      selected: widget.active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: HmColors.tint(base, alpha),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lit ? HmColors.tint(base, HmColors.ring) : Colors.transparent),
            ),
            child: Text(widget.label.toUpperCase(), style: HmText.nav.copyWith(color: lit || _hot ? base : HmColors.muted)),
          ),
        ),
      ),
    );
  }
}

/// Phone header (M4.1): logo and a live connection dot (App. D).
class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) => _TitleBar(
    child: Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        border: Border(bottom: BorderSide(color: HmColors.border)),
      ),
      child: Row(
        children: [
          Text('CloudSync', style: HmText.logo.copyWith(fontSize: 18)),
          const Spacer(),
          HmDot(ok: online, label: online ? tr('Online', 'В сети') : tr('Offline', 'Не в сети')),
          // On a narrow desktop window the window buttons take this place.
          if (!DesktopWindow.supported) ...[
            const SizedBox(width: 8),
            Text(online ? tr('online', 'в сети') : tr('offline', 'не в сети'), style: HmText.footer),
          ],
          if (DesktopWindow.supported) ...[const SizedBox(width: 8), const _WindowButtons()],
        ],
      ),
    ),
  );
}

/// Desktop status bar (§ 6): version and build, online and env pills.
class _Footer extends StatelessWidget {
  const _Footer({required this.core});

  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final device = core.state?.deviceName ?? '';
    final mount = core.state?.mountPoint ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0x0A00D4FF), Color(0x0000D4FF)]),
        border: Border(top: BorderSide(color: HmColors.border)),
      ),
      child: DefaultTextStyle(
        style: HmText.footer,
        child: Row(
          children: [
            BuildInfo(core: core),
            const Spacer(),
            StatusPills(core: core),
            const Spacer(),
            if (device.isNotEmpty) Text(device.toUpperCase()),
            if (mount.isNotEmpty) ...[const Opacity(opacity: 0.4, child: Text('  ·  ')), Text(mount)],
          ],
        ),
      ),
    );
  }
}

/// App and core (daemon) versions; the core's turns amber when it is from
/// another build, e.g. an old daemon still running after an update.
class BuildInfo extends StatelessWidget {
  const BuildInfo({super.key, required this.core});

  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final st = core.state;
    const dot = Opacity(opacity: 0.4, child: Text('  ·  '));
    final children = <Widget>[Text('CLOUDSYNC V${AppConfig.version}'), dot, Text('APP ${AppConfig.buildId}'.toUpperCase())];
    if (st != null && core.conn == Conn.ready) {
      final same = st.coreVersion == AppConfig.version && st.coreBuild == AppConfig.buildId;
      final coreBuild = st.coreBuild.isEmpty ? '?' : '${st.coreVersion} ${st.coreBuild}';
      children.addAll([
        dot,
        Text(
          'CORE $coreBuild${same ? '' : tr(' — differs from the app', ' — не совпадает с приложением')}'.toUpperCase(),
          style: same ? null : const TextStyle(color: HmColors.warning),
        ),
      ]);
    }
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }
}

/// The online pill (§ 6.3); also shown on the phone's Vault screen (App. D).
class StatusPills extends StatelessWidget {
  const StatusPills({super.key, required this.core});

  final CoreState core;

  @override
  Widget build(BuildContext context) {
    final online = core.online;
    final why = core.conn != Conn.ready
        ? tr('no connection to the core', 'нет связи с ядром')
        : (online ? tr('online', 'в сети') : tr('storages unreachable', 'хранилища недоступны'));
    return HmPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HmDot(ok: online),
          const SizedBox(width: 6),
          Text(why.toUpperCase()),
        ],
      ),
    );
  }
}
