import 'dart:async';

import 'package:grpc/grpc.dart';

import 'endpoint.dart';
import 'gen/cloudsync.pbgrpc.dart';
import '../../core/i18n.dart';

/// The gRPC client of the core, with the bearer token on every call.
class CoreClient {
  CoreClient._(this._channel, this.api, this.options);

  final ClientChannel _channel;
  final CloudSyncClient api;
  final CallOptions options;

  static Future<CoreClient> connect(CoreLauncher launcher) async {
    final e = await launcher.endpoint();
    final ch = ClientChannel(
      e.address,
      port: e.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure(), idleTimeout: Duration(minutes: 5)),
    );
    final opts = CallOptions(metadata: {'authorization': 'Bearer ${e.token}'});
    return CoreClient._(ch, CloudSyncClient(ch, options: opts), opts);
  }

  /// Options for a call that should give up after [timeout].
  CallOptions timeout(Duration timeout) => CallOptions(timeout: timeout);

  Future<void> close() => _channel.shutdown();
}

/// A short human message for a failed call.
String errorText(Object e) {
  if (e is GrpcError) {
    final m = e.message ?? '';
    return switch (e.code) {
      StatusCode.unavailable => tr('No connection to the core', 'Нет связи с ядром') + (m.isEmpty ? '' : ': $m'),
      StatusCode.permissionDenied => tr('Wrong password', 'Неверный пароль'),
      StatusCode.aborted when m.contains('open on') => m,
      StatusCode.deadlineExceeded => tr('Timed out', 'Превышено время ожидания'),
      _ => m.isEmpty ? e.codeName : m,
    };
  }
  return e.toString();
}
