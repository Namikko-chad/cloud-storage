// This is a generated file - do not edit.
//
// Generated from cloudsync.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cloudsync.pb.dart' as $0;

export 'cloudsync.pb.dart';

/// CloudSync is served by the core: by cloudsyncd on desktops (unix socket
/// or named pipe) and in-process on Android. The Flutter app is a client.
@$pb.GrpcServiceName('cloudsync.v1.CloudSync')
class CloudSyncClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CloudSyncClient(super.channel, {super.options, super.interceptors});

  /// Vault lifecycle.
  $grpc.ResponseFuture<$0.State> getState(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getState, request, options: options);
  }

  $grpc.ResponseFuture<$0.State> createVault(
    $0.CreateVaultRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createVault, request, options: options);
  }

  $grpc.ResponseFuture<$0.State> importVault(
    $0.ImportVaultRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$importVault, request, options: options);
  }

  $grpc.ResponseFuture<$0.State> unlock(
    $0.UnlockRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unlock, request, options: options);
  }

  $grpc.ResponseFuture<$0.State> lockVault(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lockVault, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> changePassword(
    $0.ChangePasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changePassword, request, options: options);
  }

  /// PermissionDenied unless the password opens the vault file (e.g. before
  /// saving it for fingerprint unlock).
  $grpc.ResponseFuture<$0.Empty> checkPassword(
    $0.CheckPasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkPassword, request, options: options);
  }

  $grpc.ResponseFuture<$0.VaultFile> exportVault(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$exportVault, request, options: options);
  }

  /// Storages.
  $grpc.ResponseFuture<$0.BackendTypesReply> backendTypes(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$backendTypes, request, options: options);
  }

  $grpc.ResponseFuture<$0.Backend> addBackend(
    $0.AddBackendRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addBackend, request, options: options);
  }

  $grpc.ResponseFuture<$0.Backend> setBackendEnabled(
    $0.SetBackendEnabledRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setBackendEnabled, request, options: options);
  }

  $grpc.ResponseFuture<$0.Backend> renameBackend(
    $0.RenameBackendRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameBackend, request, options: options);
  }

  /// Deletes a disabled storage no file uses any more (Repair moves data off).
  /// With force it goes even then: its shards count as lost (for a storage
  /// that is gone for good); Repair rebuilds what other shards allow.
  $grpc.ResponseFuture<$0.Empty> removeBackend(
    $0.RemoveBackendRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeBackend, request, options: options);
  }

  /// Browser sign-in for OAuth storages: the first reply carries the URL to
  /// open on this device, the last one the token for AddBackend params.
  $grpc.ResponseStream<$0.AuthorizeReply> authorize(
    $0.AuthorizeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$authorize, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// Signs in to the account of an existing OAuth storage again (revoked or
  /// expired token) and saves the new token; ID and data stay. Replies: the
  /// URL to open, then the account (token not sent). Refuses another account.
  $grpc.ResponseStream<$0.AuthorizeReply> reconnect(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$reconnect, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.StatusReply> status(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$status, request, options: options);
  }

  /// Recent core events: storage failures, sync errors, mounts.
  $grpc.ResponseFuture<$0.LogsReply> logs(
    $0.LogsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$logs, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> clearLogs(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$clearLogs, request, options: options);
  }

  /// Desktop: the folder the vault is shown in (empty = do not mount).
  /// Remounts at once when unlocked; kept for later starts.
  $grpc.ResponseFuture<$0.State> setMountPoint(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setMountPoint, request, options: options);
  }

  /// Desktop: locks the vault and stops the daemon (the app starts it again
  /// when it reconnects).
  $grpc.ResponseFuture<$0.Empty> shutdown(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$shutdown, request, options: options);
  }

  /// Files.
  $grpc.ResponseFuture<$0.ListReply> list(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$list, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListReply> search(
    $0.SearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$search, request, options: options);
  }

  $grpc.ResponseFuture<$0.Entry> stat(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stat, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> mkdir(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$mkdir, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> remove(
    $0.RemoveRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$remove, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> rename(
    $0.RenameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rename, request, options: options);
  }

  $grpc.ResponseFuture<$0.UploadReply> upload(
    $0.UploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$upload, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> download(
    $0.DownloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$download, request, options: options);
  }

  /// Keeping files on this device.
  $grpc.ResponseFuture<$0.Empty> pin(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pin, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> unpin(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unpin, request, options: options);
  }

  /// Locks: who has a file open for writing.
  $grpc.ResponseFuture<$0.LockInfo> lockHolder(
    $0.PathRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lockHolder, request, options: options);
  }

  $grpc.ResponseFuture<$0.LocksReply> locks(
    $0.PathsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$locks, request, options: options);
  }

  /// Maintenance.
  $grpc.ResponseFuture<$0.Empty> sync(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sync, request, options: options);
  }

  /// Checks every shard, rewrites lost ones, re-encodes after a k/m change.
  $grpc.ResponseFuture<$0.RepairReply> repair(
    $0.RepairRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$repair, request, options: options);
  }

  /// Removes data no file uses (after a grace period, see GCRequest).
  $grpc.ResponseFuture<$0.GCReply> gC(
    $0.GCRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$gC, request, options: options);
  }

  /// k/m for new files; Repair re-encodes existing ones.
  $grpc.ResponseFuture<$0.Empty> setRedundancy(
    $0.SetRedundancyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setRedundancy, request, options: options);
  }

  /// Password safe: passwords, SSH and web3 keys in groups. Lists carry no
  /// secret fields; GetSecret opens one entry (show it, then forget it).
  $grpc.ResponseFuture<$0.SecretsReply> listSecrets(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSecrets, request, options: options);
  }

  $grpc.ResponseFuture<$0.SecretEntry> getSecret(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSecret, request, options: options);
  }

  /// Creates (empty id) or replaces an entry; returns it without secrets.
  $grpc.ResponseFuture<$0.SecretEntry> putSecret(
    $0.SecretEntry request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putSecret, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteSecret(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSecret, request, options: options);
  }

  $grpc.ResponseFuture<$0.SecretGroup> putSecretGroup(
    $0.SecretGroup request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putSecretGroup, request, options: options);
  }

  /// Entries of a removed group stay, without a group.
  $grpc.ResponseFuture<$0.Empty> deleteSecretGroup(
    $0.IdRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSecretGroup, request, options: options);
  }

  /// Public key of a private key, for the editor; nothing is stored.
  $grpc.ResponseFuture<$0.DerivedKey> deriveKey(
    $0.DeriveKeyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deriveKey, request, options: options);
  }

  /// Current codes of every TOTP entry (the secrets stay in the core).
  $grpc.ResponseFuture<$0.TotpCodesReply> totpCodes(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$totpCodes, request, options: options);
  }

  /// Removes a used recovery code from a TOTP entry; returns it without secrets.
  $grpc.ResponseFuture<$0.SecretEntry> useRecoveryCode(
    $0.RecoveryCodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$useRecoveryCode, request, options: options);
  }

  /// Reads a TOTP secret / otpauth:// URI and pasted recovery codes, for
  /// the editor; nothing is stored.
  $grpc.ResponseFuture<$0.TotpPreview> checkTotp(
    $0.CheckTotpRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkTotp, request, options: options);
  }

  /// Events for live UI updates.
  $grpc.ResponseStream<$0.Event> watch(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$watch, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getState = $grpc.ClientMethod<$0.Empty, $0.State>(
      '/cloudsync.v1.CloudSync/GetState',
      ($0.Empty value) => value.writeToBuffer(),
      $0.State.fromBuffer);
  static final _$createVault =
      $grpc.ClientMethod<$0.CreateVaultRequest, $0.State>(
          '/cloudsync.v1.CloudSync/CreateVault',
          ($0.CreateVaultRequest value) => value.writeToBuffer(),
          $0.State.fromBuffer);
  static final _$importVault =
      $grpc.ClientMethod<$0.ImportVaultRequest, $0.State>(
          '/cloudsync.v1.CloudSync/ImportVault',
          ($0.ImportVaultRequest value) => value.writeToBuffer(),
          $0.State.fromBuffer);
  static final _$unlock = $grpc.ClientMethod<$0.UnlockRequest, $0.State>(
      '/cloudsync.v1.CloudSync/Unlock',
      ($0.UnlockRequest value) => value.writeToBuffer(),
      $0.State.fromBuffer);
  static final _$lockVault = $grpc.ClientMethod<$0.Empty, $0.State>(
      '/cloudsync.v1.CloudSync/LockVault',
      ($0.Empty value) => value.writeToBuffer(),
      $0.State.fromBuffer);
  static final _$changePassword =
      $grpc.ClientMethod<$0.ChangePasswordRequest, $0.Empty>(
          '/cloudsync.v1.CloudSync/ChangePassword',
          ($0.ChangePasswordRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$checkPassword =
      $grpc.ClientMethod<$0.CheckPasswordRequest, $0.Empty>(
          '/cloudsync.v1.CloudSync/CheckPassword',
          ($0.CheckPasswordRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$exportVault = $grpc.ClientMethod<$0.Empty, $0.VaultFile>(
      '/cloudsync.v1.CloudSync/ExportVault',
      ($0.Empty value) => value.writeToBuffer(),
      $0.VaultFile.fromBuffer);
  static final _$backendTypes =
      $grpc.ClientMethod<$0.Empty, $0.BackendTypesReply>(
          '/cloudsync.v1.CloudSync/BackendTypes',
          ($0.Empty value) => value.writeToBuffer(),
          $0.BackendTypesReply.fromBuffer);
  static final _$addBackend =
      $grpc.ClientMethod<$0.AddBackendRequest, $0.Backend>(
          '/cloudsync.v1.CloudSync/AddBackend',
          ($0.AddBackendRequest value) => value.writeToBuffer(),
          $0.Backend.fromBuffer);
  static final _$setBackendEnabled =
      $grpc.ClientMethod<$0.SetBackendEnabledRequest, $0.Backend>(
          '/cloudsync.v1.CloudSync/SetBackendEnabled',
          ($0.SetBackendEnabledRequest value) => value.writeToBuffer(),
          $0.Backend.fromBuffer);
  static final _$renameBackend =
      $grpc.ClientMethod<$0.RenameBackendRequest, $0.Backend>(
          '/cloudsync.v1.CloudSync/RenameBackend',
          ($0.RenameBackendRequest value) => value.writeToBuffer(),
          $0.Backend.fromBuffer);
  static final _$removeBackend =
      $grpc.ClientMethod<$0.RemoveBackendRequest, $0.Empty>(
          '/cloudsync.v1.CloudSync/RemoveBackend',
          ($0.RemoveBackendRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$authorize =
      $grpc.ClientMethod<$0.AuthorizeRequest, $0.AuthorizeReply>(
          '/cloudsync.v1.CloudSync/Authorize',
          ($0.AuthorizeRequest value) => value.writeToBuffer(),
          $0.AuthorizeReply.fromBuffer);
  static final _$reconnect =
      $grpc.ClientMethod<$0.IdRequest, $0.AuthorizeReply>(
          '/cloudsync.v1.CloudSync/Reconnect',
          ($0.IdRequest value) => value.writeToBuffer(),
          $0.AuthorizeReply.fromBuffer);
  static final _$status = $grpc.ClientMethod<$0.Empty, $0.StatusReply>(
      '/cloudsync.v1.CloudSync/Status',
      ($0.Empty value) => value.writeToBuffer(),
      $0.StatusReply.fromBuffer);
  static final _$logs = $grpc.ClientMethod<$0.LogsRequest, $0.LogsReply>(
      '/cloudsync.v1.CloudSync/Logs',
      ($0.LogsRequest value) => value.writeToBuffer(),
      $0.LogsReply.fromBuffer);
  static final _$clearLogs = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/cloudsync.v1.CloudSync/ClearLogs',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$setMountPoint = $grpc.ClientMethod<$0.PathRequest, $0.State>(
      '/cloudsync.v1.CloudSync/SetMountPoint',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.State.fromBuffer);
  static final _$shutdown = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/cloudsync.v1.CloudSync/Shutdown',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$list = $grpc.ClientMethod<$0.PathRequest, $0.ListReply>(
      '/cloudsync.v1.CloudSync/List',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.ListReply.fromBuffer);
  static final _$search = $grpc.ClientMethod<$0.SearchRequest, $0.ListReply>(
      '/cloudsync.v1.CloudSync/Search',
      ($0.SearchRequest value) => value.writeToBuffer(),
      $0.ListReply.fromBuffer);
  static final _$stat = $grpc.ClientMethod<$0.PathRequest, $0.Entry>(
      '/cloudsync.v1.CloudSync/Stat',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.Entry.fromBuffer);
  static final _$mkdir = $grpc.ClientMethod<$0.PathRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/Mkdir',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$remove = $grpc.ClientMethod<$0.RemoveRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/Remove',
      ($0.RemoveRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$rename = $grpc.ClientMethod<$0.RenameRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/Rename',
      ($0.RenameRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$upload = $grpc.ClientMethod<$0.UploadRequest, $0.UploadReply>(
      '/cloudsync.v1.CloudSync/Upload',
      ($0.UploadRequest value) => value.writeToBuffer(),
      $0.UploadReply.fromBuffer);
  static final _$download = $grpc.ClientMethod<$0.DownloadRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/Download',
      ($0.DownloadRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$pin = $grpc.ClientMethod<$0.PathRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/Pin',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$unpin = $grpc.ClientMethod<$0.PathRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/Unpin',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$lockHolder = $grpc.ClientMethod<$0.PathRequest, $0.LockInfo>(
      '/cloudsync.v1.CloudSync/LockHolder',
      ($0.PathRequest value) => value.writeToBuffer(),
      $0.LockInfo.fromBuffer);
  static final _$locks = $grpc.ClientMethod<$0.PathsRequest, $0.LocksReply>(
      '/cloudsync.v1.CloudSync/Locks',
      ($0.PathsRequest value) => value.writeToBuffer(),
      $0.LocksReply.fromBuffer);
  static final _$sync = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/cloudsync.v1.CloudSync/Sync',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$repair = $grpc.ClientMethod<$0.RepairRequest, $0.RepairReply>(
      '/cloudsync.v1.CloudSync/Repair',
      ($0.RepairRequest value) => value.writeToBuffer(),
      $0.RepairReply.fromBuffer);
  static final _$gC = $grpc.ClientMethod<$0.GCRequest, $0.GCReply>(
      '/cloudsync.v1.CloudSync/GC',
      ($0.GCRequest value) => value.writeToBuffer(),
      $0.GCReply.fromBuffer);
  static final _$setRedundancy =
      $grpc.ClientMethod<$0.SetRedundancyRequest, $0.Empty>(
          '/cloudsync.v1.CloudSync/SetRedundancy',
          ($0.SetRedundancyRequest value) => value.writeToBuffer(),
          $0.Empty.fromBuffer);
  static final _$listSecrets = $grpc.ClientMethod<$0.Empty, $0.SecretsReply>(
      '/cloudsync.v1.CloudSync/ListSecrets',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SecretsReply.fromBuffer);
  static final _$getSecret = $grpc.ClientMethod<$0.IdRequest, $0.SecretEntry>(
      '/cloudsync.v1.CloudSync/GetSecret',
      ($0.IdRequest value) => value.writeToBuffer(),
      $0.SecretEntry.fromBuffer);
  static final _$putSecret = $grpc.ClientMethod<$0.SecretEntry, $0.SecretEntry>(
      '/cloudsync.v1.CloudSync/PutSecret',
      ($0.SecretEntry value) => value.writeToBuffer(),
      $0.SecretEntry.fromBuffer);
  static final _$deleteSecret = $grpc.ClientMethod<$0.IdRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/DeleteSecret',
      ($0.IdRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$putSecretGroup =
      $grpc.ClientMethod<$0.SecretGroup, $0.SecretGroup>(
          '/cloudsync.v1.CloudSync/PutSecretGroup',
          ($0.SecretGroup value) => value.writeToBuffer(),
          $0.SecretGroup.fromBuffer);
  static final _$deleteSecretGroup = $grpc.ClientMethod<$0.IdRequest, $0.Empty>(
      '/cloudsync.v1.CloudSync/DeleteSecretGroup',
      ($0.IdRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$deriveKey =
      $grpc.ClientMethod<$0.DeriveKeyRequest, $0.DerivedKey>(
          '/cloudsync.v1.CloudSync/DeriveKey',
          ($0.DeriveKeyRequest value) => value.writeToBuffer(),
          $0.DerivedKey.fromBuffer);
  static final _$totpCodes = $grpc.ClientMethod<$0.Empty, $0.TotpCodesReply>(
      '/cloudsync.v1.CloudSync/TotpCodes',
      ($0.Empty value) => value.writeToBuffer(),
      $0.TotpCodesReply.fromBuffer);
  static final _$useRecoveryCode =
      $grpc.ClientMethod<$0.RecoveryCodeRequest, $0.SecretEntry>(
          '/cloudsync.v1.CloudSync/UseRecoveryCode',
          ($0.RecoveryCodeRequest value) => value.writeToBuffer(),
          $0.SecretEntry.fromBuffer);
  static final _$checkTotp =
      $grpc.ClientMethod<$0.CheckTotpRequest, $0.TotpPreview>(
          '/cloudsync.v1.CloudSync/CheckTotp',
          ($0.CheckTotpRequest value) => value.writeToBuffer(),
          $0.TotpPreview.fromBuffer);
  static final _$watch = $grpc.ClientMethod<$0.Empty, $0.Event>(
      '/cloudsync.v1.CloudSync/Watch',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Event.fromBuffer);
}

@$pb.GrpcServiceName('cloudsync.v1.CloudSync')
abstract class CloudSyncServiceBase extends $grpc.Service {
  $core.String get $name => 'cloudsync.v1.CloudSync';

  CloudSyncServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.State>(
        'GetState',
        getState_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateVaultRequest, $0.State>(
        'CreateVault',
        createVault_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateVaultRequest.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ImportVaultRequest, $0.State>(
        'ImportVault',
        importVault_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ImportVaultRequest.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UnlockRequest, $0.State>(
        'Unlock',
        unlock_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UnlockRequest.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.State>(
        'LockVault',
        lockVault_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangePasswordRequest, $0.Empty>(
        'ChangePassword',
        changePassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangePasswordRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CheckPasswordRequest, $0.Empty>(
        'CheckPassword',
        checkPassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CheckPasswordRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.VaultFile>(
        'ExportVault',
        exportVault_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.VaultFile value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.BackendTypesReply>(
        'BackendTypes',
        backendTypes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.BackendTypesReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddBackendRequest, $0.Backend>(
        'AddBackend',
        addBackend_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddBackendRequest.fromBuffer(value),
        ($0.Backend value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetBackendEnabledRequest, $0.Backend>(
        'SetBackendEnabled',
        setBackendEnabled_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetBackendEnabledRequest.fromBuffer(value),
        ($0.Backend value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameBackendRequest, $0.Backend>(
        'RenameBackend',
        renameBackend_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RenameBackendRequest.fromBuffer(value),
        ($0.Backend value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveBackendRequest, $0.Empty>(
        'RemoveBackend',
        removeBackend_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RemoveBackendRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AuthorizeRequest, $0.AuthorizeReply>(
        'Authorize',
        authorize_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.AuthorizeRequest.fromBuffer(value),
        ($0.AuthorizeReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.AuthorizeReply>(
        'Reconnect',
        reconnect_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.AuthorizeReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.StatusReply>(
        'Status',
        status_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.StatusReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LogsRequest, $0.LogsReply>(
        'Logs',
        logs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LogsRequest.fromBuffer(value),
        ($0.LogsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'ClearLogs',
        clearLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.State>(
        'SetMountPoint',
        setMountPoint_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'Shutdown',
        shutdown_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.ListReply>(
        'List',
        list_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.ListReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchRequest, $0.ListReply>(
        'Search',
        search_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SearchRequest.fromBuffer(value),
        ($0.ListReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.Entry>(
        'Stat',
        stat_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.Entry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.Empty>(
        'Mkdir',
        mkdir_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveRequest, $0.Empty>(
        'Remove',
        remove_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RemoveRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameRequest, $0.Empty>(
        'Rename',
        rename_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RenameRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadRequest, $0.UploadReply>(
        'Upload',
        upload_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UploadRequest.fromBuffer(value),
        ($0.UploadReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadRequest, $0.Empty>(
        'Download',
        download_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DownloadRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.Empty>(
        'Pin',
        pin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.Empty>(
        'Unpin',
        unpin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathRequest, $0.LockInfo>(
        'LockHolder',
        lockHolder_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathRequest.fromBuffer(value),
        ($0.LockInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PathsRequest, $0.LocksReply>(
        'Locks',
        locks_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PathsRequest.fromBuffer(value),
        ($0.LocksReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'Sync',
        sync_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RepairRequest, $0.RepairReply>(
        'Repair',
        repair_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RepairRequest.fromBuffer(value),
        ($0.RepairReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GCRequest, $0.GCReply>(
        'GC',
        gC_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GCRequest.fromBuffer(value),
        ($0.GCReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetRedundancyRequest, $0.Empty>(
        'SetRedundancy',
        setRedundancy_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetRedundancyRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SecretsReply>(
        'ListSecrets',
        listSecrets_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SecretsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.SecretEntry>(
        'GetSecret',
        getSecret_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.SecretEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SecretEntry, $0.SecretEntry>(
        'PutSecret',
        putSecret_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SecretEntry.fromBuffer(value),
        ($0.SecretEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.Empty>(
        'DeleteSecret',
        deleteSecret_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SecretGroup, $0.SecretGroup>(
        'PutSecretGroup',
        putSecretGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SecretGroup.fromBuffer(value),
        ($0.SecretGroup value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IdRequest, $0.Empty>(
        'DeleteSecretGroup',
        deleteSecretGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.IdRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeriveKeyRequest, $0.DerivedKey>(
        'DeriveKey',
        deriveKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeriveKeyRequest.fromBuffer(value),
        ($0.DerivedKey value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.TotpCodesReply>(
        'TotpCodes',
        totpCodes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.TotpCodesReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RecoveryCodeRequest, $0.SecretEntry>(
        'UseRecoveryCode',
        useRecoveryCode_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RecoveryCodeRequest.fromBuffer(value),
        ($0.SecretEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CheckTotpRequest, $0.TotpPreview>(
        'CheckTotp',
        checkTotp_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CheckTotpRequest.fromBuffer(value),
        ($0.TotpPreview value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Event>(
        'Watch',
        watch_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Event value) => value.writeToBuffer()));
  }

  $async.Future<$0.State> getState_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getState($call, await $request);
  }

  $async.Future<$0.State> getState($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.State> createVault_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateVaultRequest> $request) async {
    return createVault($call, await $request);
  }

  $async.Future<$0.State> createVault(
      $grpc.ServiceCall call, $0.CreateVaultRequest request);

  $async.Future<$0.State> importVault_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ImportVaultRequest> $request) async {
    return importVault($call, await $request);
  }

  $async.Future<$0.State> importVault(
      $grpc.ServiceCall call, $0.ImportVaultRequest request);

  $async.Future<$0.State> unlock_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.UnlockRequest> $request) async {
    return unlock($call, await $request);
  }

  $async.Future<$0.State> unlock(
      $grpc.ServiceCall call, $0.UnlockRequest request);

  $async.Future<$0.State> lockVault_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return lockVault($call, await $request);
  }

  $async.Future<$0.State> lockVault($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Empty> changePassword_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ChangePasswordRequest> $request) async {
    return changePassword($call, await $request);
  }

  $async.Future<$0.Empty> changePassword(
      $grpc.ServiceCall call, $0.ChangePasswordRequest request);

  $async.Future<$0.Empty> checkPassword_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CheckPasswordRequest> $request) async {
    return checkPassword($call, await $request);
  }

  $async.Future<$0.Empty> checkPassword(
      $grpc.ServiceCall call, $0.CheckPasswordRequest request);

  $async.Future<$0.VaultFile> exportVault_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return exportVault($call, await $request);
  }

  $async.Future<$0.VaultFile> exportVault(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.BackendTypesReply> backendTypes_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return backendTypes($call, await $request);
  }

  $async.Future<$0.BackendTypesReply> backendTypes(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Backend> addBackend_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddBackendRequest> $request) async {
    return addBackend($call, await $request);
  }

  $async.Future<$0.Backend> addBackend(
      $grpc.ServiceCall call, $0.AddBackendRequest request);

  $async.Future<$0.Backend> setBackendEnabled_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetBackendEnabledRequest> $request) async {
    return setBackendEnabled($call, await $request);
  }

  $async.Future<$0.Backend> setBackendEnabled(
      $grpc.ServiceCall call, $0.SetBackendEnabledRequest request);

  $async.Future<$0.Backend> renameBackend_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RenameBackendRequest> $request) async {
    return renameBackend($call, await $request);
  }

  $async.Future<$0.Backend> renameBackend(
      $grpc.ServiceCall call, $0.RenameBackendRequest request);

  $async.Future<$0.Empty> removeBackend_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RemoveBackendRequest> $request) async {
    return removeBackend($call, await $request);
  }

  $async.Future<$0.Empty> removeBackend(
      $grpc.ServiceCall call, $0.RemoveBackendRequest request);

  $async.Stream<$0.AuthorizeReply> authorize_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AuthorizeRequest> $request) async* {
    yield* authorize($call, await $request);
  }

  $async.Stream<$0.AuthorizeReply> authorize(
      $grpc.ServiceCall call, $0.AuthorizeRequest request);

  $async.Stream<$0.AuthorizeReply> reconnect_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async* {
    yield* reconnect($call, await $request);
  }

  $async.Stream<$0.AuthorizeReply> reconnect(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$0.StatusReply> status_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return status($call, await $request);
  }

  $async.Future<$0.StatusReply> status(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.LogsReply> logs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LogsRequest> $request) async {
    return logs($call, await $request);
  }

  $async.Future<$0.LogsReply> logs(
      $grpc.ServiceCall call, $0.LogsRequest request);

  $async.Future<$0.Empty> clearLogs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return clearLogs($call, await $request);
  }

  $async.Future<$0.Empty> clearLogs($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.State> setMountPoint_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return setMountPoint($call, await $request);
  }

  $async.Future<$0.State> setMountPoint(
      $grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.Empty> shutdown_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return shutdown($call, await $request);
  }

  $async.Future<$0.Empty> shutdown($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.ListReply> list_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return list($call, await $request);
  }

  $async.Future<$0.ListReply> list(
      $grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.ListReply> search_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SearchRequest> $request) async {
    return search($call, await $request);
  }

  $async.Future<$0.ListReply> search(
      $grpc.ServiceCall call, $0.SearchRequest request);

  $async.Future<$0.Entry> stat_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return stat($call, await $request);
  }

  $async.Future<$0.Entry> stat($grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.Empty> mkdir_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return mkdir($call, await $request);
  }

  $async.Future<$0.Empty> mkdir($grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.Empty> remove_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RemoveRequest> $request) async {
    return remove($call, await $request);
  }

  $async.Future<$0.Empty> remove(
      $grpc.ServiceCall call, $0.RemoveRequest request);

  $async.Future<$0.Empty> rename_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RenameRequest> $request) async {
    return rename($call, await $request);
  }

  $async.Future<$0.Empty> rename(
      $grpc.ServiceCall call, $0.RenameRequest request);

  $async.Future<$0.UploadReply> upload_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.UploadRequest> $request) async {
    return upload($call, await $request);
  }

  $async.Future<$0.UploadReply> upload(
      $grpc.ServiceCall call, $0.UploadRequest request);

  $async.Future<$0.Empty> download_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadRequest> $request) async {
    return download($call, await $request);
  }

  $async.Future<$0.Empty> download(
      $grpc.ServiceCall call, $0.DownloadRequest request);

  $async.Future<$0.Empty> pin_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return pin($call, await $request);
  }

  $async.Future<$0.Empty> pin($grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.Empty> unpin_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return unpin($call, await $request);
  }

  $async.Future<$0.Empty> unpin($grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.LockInfo> lockHolder_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathRequest> $request) async {
    return lockHolder($call, await $request);
  }

  $async.Future<$0.LockInfo> lockHolder(
      $grpc.ServiceCall call, $0.PathRequest request);

  $async.Future<$0.LocksReply> locks_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PathsRequest> $request) async {
    return locks($call, await $request);
  }

  $async.Future<$0.LocksReply> locks(
      $grpc.ServiceCall call, $0.PathsRequest request);

  $async.Future<$0.Empty> sync_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return sync($call, await $request);
  }

  $async.Future<$0.Empty> sync($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.RepairReply> repair_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RepairRequest> $request) async {
    return repair($call, await $request);
  }

  $async.Future<$0.RepairReply> repair(
      $grpc.ServiceCall call, $0.RepairRequest request);

  $async.Future<$0.GCReply> gC_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.GCRequest> $request) async {
    return gC($call, await $request);
  }

  $async.Future<$0.GCReply> gC($grpc.ServiceCall call, $0.GCRequest request);

  $async.Future<$0.Empty> setRedundancy_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetRedundancyRequest> $request) async {
    return setRedundancy($call, await $request);
  }

  $async.Future<$0.Empty> setRedundancy(
      $grpc.ServiceCall call, $0.SetRedundancyRequest request);

  $async.Future<$0.SecretsReply> listSecrets_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listSecrets($call, await $request);
  }

  $async.Future<$0.SecretsReply> listSecrets(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SecretEntry> getSecret_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return getSecret($call, await $request);
  }

  $async.Future<$0.SecretEntry> getSecret(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$0.SecretEntry> putSecret_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SecretEntry> $request) async {
    return putSecret($call, await $request);
  }

  $async.Future<$0.SecretEntry> putSecret(
      $grpc.ServiceCall call, $0.SecretEntry request);

  $async.Future<$0.Empty> deleteSecret_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return deleteSecret($call, await $request);
  }

  $async.Future<$0.Empty> deleteSecret(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$0.SecretGroup> putSecretGroup_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SecretGroup> $request) async {
    return putSecretGroup($call, await $request);
  }

  $async.Future<$0.SecretGroup> putSecretGroup(
      $grpc.ServiceCall call, $0.SecretGroup request);

  $async.Future<$0.Empty> deleteSecretGroup_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.IdRequest> $request) async {
    return deleteSecretGroup($call, await $request);
  }

  $async.Future<$0.Empty> deleteSecretGroup(
      $grpc.ServiceCall call, $0.IdRequest request);

  $async.Future<$0.DerivedKey> deriveKey_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeriveKeyRequest> $request) async {
    return deriveKey($call, await $request);
  }

  $async.Future<$0.DerivedKey> deriveKey(
      $grpc.ServiceCall call, $0.DeriveKeyRequest request);

  $async.Future<$0.TotpCodesReply> totpCodes_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return totpCodes($call, await $request);
  }

  $async.Future<$0.TotpCodesReply> totpCodes(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SecretEntry> useRecoveryCode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RecoveryCodeRequest> $request) async {
    return useRecoveryCode($call, await $request);
  }

  $async.Future<$0.SecretEntry> useRecoveryCode(
      $grpc.ServiceCall call, $0.RecoveryCodeRequest request);

  $async.Future<$0.TotpPreview> checkTotp_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CheckTotpRequest> $request) async {
    return checkTotp($call, await $request);
  }

  $async.Future<$0.TotpPreview> checkTotp(
      $grpc.ServiceCall call, $0.CheckTotpRequest request);

  $async.Stream<$0.Event> watch_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* watch($call, await $request);
  }

  $async.Stream<$0.Event> watch($grpc.ServiceCall call, $0.Empty request);
}
