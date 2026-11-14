import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

/// Signs in to the account of storage [b] again (expired or revoked token).
/// Returns the account on success, null when cancelled or failed.
Future<String?> showReconnectStorage(BuildContext context, pb.Backend b) {
  final core = context.read<CoreCubit>();
  return showHmModal<String>(
    context,
    title: tr('Reconnect “${b.name}”', 'Переподключить «${b.name}»'),
    dismissible: false,
    body: (ctx) => _Reconnect(core: core, b: b),
    actions: (ctx) => [HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: Hm.of(ctx).mobile, onPressed: () => Navigator.pop(ctx))],
  );
}

class _Reconnect extends StatefulWidget {
  const _Reconnect({required this.core, required this.b});

  final CoreCubit core;
  final pb.Backend b;

  @override
  State<_Reconnect> createState() => _ReconnectState();
}

class _ReconnectState extends State<_Reconnect> {
  StreamSubscription<pb.AuthorizeReply>? _sub;
  String? _url;
  String? _error;
  bool _waiting = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _sub?.cancel();
    setState(() {
      _waiting = true;
      _error = null;
      _url = null;
    });
    String? account;
    _sub = widget.core.api
        .reconnect(pb.IdRequest(id: widget.b.id))
        .listen(
          (r) async {
            if (r.url.isNotEmpty) {
              if (mounted) setState(() => _url = r.url);
              await launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication);
            } else {
              account = r.account;
            }
          },
          onError: (Object e) {
            if (mounted) {
              setState(() {
                _waiting = false;
                _error = errorText(e);
              });
            }
          },
          onDone: () {
            if (mounted && _error == null) Navigator.pop(context, account ?? '');
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel(); // closing the dialog stops the sign-in in the core
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr(
            'A browser opens on this device. Sign in to the same account${b.account.isEmpty ? '' : ' (${b.account})'}: '
                'the storage keeps its ID and data, only its access is renewed.',
            'Откроется браузер на этом устройстве. Войдите в тот же аккаунт${b.account.isEmpty ? '' : ' (${b.account})'}: '
                'ID и данные хранилища остаются, обновляется только доступ.',
          ),
          style: HmText.small.copyWith(height: 1.5),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          HmBanner(tr('Sign-in failed: ', 'Вход не удался: ') + _error!, tone: HmTone.error),
          const SizedBox(height: 12),
          HmButton(tr('Try again', 'Попробовать снова'), icon: Icons.refresh, onPressed: _start),
        ] else
          HmButton(tr('Waiting for sign-in…', 'Ожидание входа…'), icon: Icons.login, loading: _waiting, onPressed: null),
        if (_url != null && _error == null) ...[
          const SizedBox(height: 8),
          SelectableText(tr('If the browser did not open: ', 'Если браузер не открылся: ') + _url!, style: HmText.jb(11, color: HmColors.muted)),
        ],
      ],
    );
  }
}
