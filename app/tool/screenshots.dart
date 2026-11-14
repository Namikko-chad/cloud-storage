// Renders every section at a desktop and a phone width against a running
// core and writes PNGs, for checking the UI against the design manifest:
//
//   SHOTS=/tmp/shots CS_PASSWORD=... flutter run -d linux -t tool/screenshots.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloudsync/app.dart';
import 'package:cloudsync/core/settings/app_settings.dart';
import 'package:cloudsync/data/rpc/endpoint.dart';
import 'package:cloudsync/data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import 'package:cloudsync/presentation/core/core_cubit.dart';
import 'package:cloudsync/presentation/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final _boundary = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  final out = Directory(Platform.environment['SHOTS'] ?? 'shots')..createSync(recursive: true);
  final core = CoreCubit(CoreLauncher.forPlatform());
  await core.connect();
  final frame = ValueNotifier<(Size, Section, int)>((const Size(1440, 900), Section.files, 0));
  runApp(
    ValueListenableBuilder(
      valueListenable: frame,
      builder: (_, f, _) => CloudSyncApp(
        key: ValueKey(f),
        core: core,
        home: AppShell(initial: f.$2),
        frame: (context, child) {
          final mq = MediaQuery.of(context);
          return RepaintBoundary(
            key: _boundary,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: f.$1.width,
              maxWidth: f.$1.width,
              minHeight: f.$1.height,
              maxHeight: f.$1.height,
              child: MediaQuery(
                data: mq.copyWith(size: f.$1, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
                child: child!,
              ),
            ),
          );
        },
      ),
    ),
  );

  const sizes = {'desktop': Size(1440, 900), 'phone': Size(390, 844)};
  Future<void> shot(String name, Size size, Section s) async {
    frame.value = (size, s, frame.value.$3 + 1);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    final ro = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 1);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    await File('${out.path}/$name.png').writeAsBytes(png!.buffer.asUint8List());
    stdout.writeln('shot ${out.path}/$name.png');
  }

  if (!core.state.unlocked) {
    for (final e in sizes.entries) {
      await shot('unlock-${e.key}', e.value, Section.files);
    }
    final pw = Platform.environment['CS_PASSWORD'] ?? '';
    core.adopt(await core.api.unlock(pb.UnlockRequest(password: pw)));
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  for (final s in Section.values) {
    for (final e in sizes.entries) {
      await shot('${s.name}-${e.key}', e.value, s);
    }
  }
  exit(0);
}
