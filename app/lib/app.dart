import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/desktop/desktop_window.dart';
import 'core/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/layout.dart';
import 'presentation/common/overlays.dart';
import 'presentation/core/core_cubit.dart';
import 'presentation/shell/app_shell.dart';

class CloudSyncApp extends StatefulWidget {
  const CloudSyncApp({super.key, required this.core, this.home = const AppShell(), this.frame});

  final CoreCubit core;
  final Widget home;

  /// Wraps the whole app (dev tools render it at a fixed size).
  final TransitionBuilder? frame;

  @override
  State<CloudSyncApp> createState() => _CloudSyncAppState();
}

class _CloudSyncAppState extends State<CloudSyncApp> {
  @override
  void initState() {
    super.initState();
    lang.addListener(_relabel);
  }

  @override
  void dispose() {
    lang.removeListener(_relabel);
    super.dispose();
  }

  /// Strings come from tr() in build methods, so a language switch
  /// rebuilds every element; state (current page, forms) is kept.
  void _relabel() {
    setState(() {});
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  CoreCubit get core => widget.core;
  Widget get home => widget.home;
  TransitionBuilder? get frame => widget.frame;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: core,
    child: MaterialApp(
      title: 'CloudSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: currentLocale,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
      // Toasts are mounted after the navigator, so they stay above
      // modals and sheets (§ 2.4) and above the tab bar on phones (M15).
      builder: (context, child) {
        final app = Stack(
          children: [
            ?child,
            BlocBuilder<CoreCubit, CoreState>(
              buildWhen: (a, b) => a.unlocked != b.unlocked,
              builder: (context, s) => ToastHost(bottomOffset: Hm.of(context).mobile && s.unlocked ? 56 : 0),
            ),
          ],
        );
        // Frameless Linux window: the app gives it resize edges.
        final framed = frame == null && DesktopWindow.supported && Platform.isLinux ? DragToResizeArea(resizeEdgeSize: 6, child: app) : app;
        return frame == null ? framed : frame!(context, app);
      },
    ),
  );
}
