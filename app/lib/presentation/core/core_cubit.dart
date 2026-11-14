import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/rpc/core_client.dart';
import '../../data/rpc/endpoint.dart';
import '../../data/rpc/gen/cloudsync.pbgrpc.dart' as pb;
import '../../core/i18n.dart';

enum Conn { connecting, ready, failed }

class CoreState extends Equatable {
  const CoreState({
    this.conn = Conn.connecting,
    this.state,
    this.status,
    this.error,
    this.treeRev = 0,
    this.secretsRev = 0,
    this.syncOk = true,
    this.syncError,
    this.lastSync,
    this.stopped = false,
  });

  final Conn conn;
  final pb.State? state;
  final pb.StatusReply? status;
  final String? error; // connection error
  final int treeRev; // bumps when files changed anywhere
  final int secretsRev; // bumps when the password safe changed here
  final bool syncOk;
  final String? syncError;
  final DateTime? lastSync;

  /// The user stopped the background service: no automatic reconnect.
  final bool stopped;

  bool get unlocked => state?.unlocked ?? false;

  /// Online: the core answers and the last sync reached the storages.
  bool get online => conn == Conn.ready && syncOk;

  CoreState copyWith({
    Conn? conn,
    pb.State? state,
    pb.StatusReply? status,
    String? error,
    int? treeRev,
    int? secretsRev,
    bool? syncOk,
    String? syncError,
    DateTime? lastSync,
    bool? stopped,
    bool clearError = false,
    bool clearStatus = false,
  }) => CoreState(
    conn: conn ?? this.conn,
    state: state ?? this.state,
    status: clearStatus ? null : status ?? this.status,
    error: clearError ? null : error ?? this.error,
    treeRev: treeRev ?? this.treeRev,
    secretsRev: secretsRev ?? this.secretsRev,
    syncOk: syncOk ?? this.syncOk,
    syncError: syncOk == true ? null : syncError ?? this.syncError,
    lastSync: lastSync ?? this.lastSync,
    stopped: stopped ?? this.stopped,
  );

  @override
  List<Object?> get props => [conn, state, status, error, treeRev, secretsRev, syncOk, syncError, lastSync, stopped];
}

/// The connection to the core and what every screen needs to know.
class CoreCubit extends Cubit<CoreState> {
  CoreCubit(this._launcher) : super(const CoreState());

  final CoreLauncher _launcher;
  CoreClient? _client;
  StreamSubscription<pb.Event>? _events;
  Timer? _statusTimer;

  pb.CloudSyncClient get api {
    final c = _client;
    if (c == null) throw StateError('not connected');
    return c.api;
  }

  Future<void> connect() async {
    emit(state.copyWith(conn: Conn.connecting, stopped: false, clearError: true));
    try {
      await _client?.close();
      _client = await CoreClient.connect(_launcher);
      final st = await api.getState(pb.Empty());
      emit(state.copyWith(conn: Conn.ready, state: st, clearError: true));
      _watch();
      if (st.unlocked) unawaited(refreshStatus());
    } catch (e) {
      emit(state.copyWith(conn: Conn.failed, error: errorText(e)));
    }
  }

  void _watch() {
    _events?.cancel();
    _events = api
        .watch(pb.Empty())
        .listen(
          (ev) {
            switch (ev.kind) {
              case pb.Event_Kind.TREE_CHANGED:
                emit(state.copyWith(treeRev: state.treeRev + 1));
              case pb.Event_Kind.SECRETS_CHANGED:
                emit(state.copyWith(secretsRev: state.secretsRev + 1));
              case pb.Event_Kind.STATE_CHANGED:
                unawaited(refreshState());
              case pb.Event_Kind.SYNC_DONE:
                emit(state.copyWith(syncOk: true, lastSync: DateTime.now()));
                _statusSoon();
              case pb.Event_Kind.SYNC_ERROR:
                emit(state.copyWith(syncOk: false, syncError: ev.message, lastSync: DateTime.now()));
                _statusSoon();
              default:
            }
          },
          onError: (_) => _lost(),
          onDone: _lost,
          cancelOnError: true,
        );
  }

  // The core went away (daemon restarted): reconnect after a pause.
  void _lost() {
    if (isClosed || state.stopped) return;
    emit(state.copyWith(conn: Conn.failed, error: tr('No connection to the core', 'Нет связи с ядром')));
    Timer(const Duration(seconds: 3), () {
      if (!isClosed && state.conn == Conn.failed) connect();
    });
  }

  void _statusSoon() {
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(milliseconds: 300), refreshStatus);
  }

  Future<void> refreshState() async {
    try {
      final st = await api.getState(pb.Empty());
      emit(state.copyWith(state: st, clearStatus: !st.unlocked));
      if (st.unlocked) await refreshStatus();
    } catch (e) {
      emit(state.copyWith(error: errorText(e)));
    }
  }

  Future<void> refreshStatus() async {
    if (!state.unlocked) return;
    try {
      final s = await api.status(pb.Empty());
      emit(state.copyWith(status: s));
    } catch (_) {}
  }

  /// Applies a state returned by an unlock / create / import call.
  void adopt(pb.State st) {
    emit(state.copyWith(state: st, clearStatus: !st.unlocked));
    if (st.unlocked) unawaited(refreshStatus());
  }

  /// Stops the background service (desktop daemon): the vault locks and
  /// sync stops until [connect] starts it again.
  Future<void> stopService() async {
    emit(state.copyWith(stopped: true));
    try {
      await api.shutdown(pb.Empty());
    } catch (_) {}
    await _events?.cancel();
    emit(
      state.copyWith(
        conn: Conn.failed,
        clearStatus: true,
        state: pb.State(),
        error: tr('The background service is stopped', 'Фоновая служба остановлена'),
      ),
    );
  }

  Future<void> lockVault() async {
    final st = await api.lockVault(pb.Empty());
    adopt(st);
  }

  /// Files changed by this app: screens reload.
  void touched() => emit(state.copyWith(treeRev: state.treeRev + 1));

  @override
  Future<void> close() async {
    await _events?.cancel();
    _statusTimer?.cancel();
    await _client?.close();
    return super.close();
  }
}
