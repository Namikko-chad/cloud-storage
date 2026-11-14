// This is a generated file - do not edit.
//
// Generated from cloudsync.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cloudsync.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'cloudsync.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  factory Empty() => Empty._();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: Empty.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Empty() / Empty.new instead')
  static Empty create() => Empty._();
  static $pb.GeneratedMessage $_createMessage() => Empty._();
  @$core.override
  Empty createEmptyInstance() => Empty._();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Empty>(Empty.$_createMessage);
  static Empty? _defaultInstance;
}

class State extends $pb.GeneratedMessage {
  factory State({
    $core.bool? vaultExists,
    $core.bool? unlocked,
    $core.String? vaultPath,
    $core.String? vaultId,
    $core.String? deviceId,
    $core.String? deviceName,
    $core.String? mountPoint,
    $core.String? platform,
    $core.bool? ready,
    $core.String? problem,
    $core.String? mountDir,
    $core.bool? canMount,
    $core.String? coreVersion,
    $core.String? coreBuild,
  }) {
    final result = State._();
    if (vaultExists != null) result.vaultExists = vaultExists;
    if (unlocked != null) result.unlocked = unlocked;
    if (vaultPath != null) result.vaultPath = vaultPath;
    if (vaultId != null) result.vaultId = vaultId;
    if (deviceId != null) result.deviceId = deviceId;
    if (deviceName != null) result.deviceName = deviceName;
    if (mountPoint != null) result.mountPoint = mountPoint;
    if (platform != null) result.platform = platform;
    if (ready != null) result.ready = ready;
    if (problem != null) result.problem = problem;
    if (mountDir != null) result.mountDir = mountDir;
    if (canMount != null) result.canMount = canMount;
    if (coreVersion != null) result.coreVersion = coreVersion;
    if (coreBuild != null) result.coreBuild = coreBuild;
    return result;
  }

  State._();

  factory State.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      State()..mergeFromBuffer(data, registry);
  factory State.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      State()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'State',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: State.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'vaultExists')
    ..aOB(2, _omitFieldNames ? '' : 'unlocked')
    ..aOS(3, _omitFieldNames ? '' : 'vaultPath')
    ..aOS(4, _omitFieldNames ? '' : 'vaultId')
    ..aOS(5, _omitFieldNames ? '' : 'deviceId')
    ..aOS(6, _omitFieldNames ? '' : 'deviceName')
    ..aOS(7, _omitFieldNames ? '' : 'mountPoint')
    ..aOS(8, _omitFieldNames ? '' : 'platform')
    ..aOB(9, _omitFieldNames ? '' : 'ready')
    ..aOS(10, _omitFieldNames ? '' : 'problem')
    ..aOS(11, _omitFieldNames ? '' : 'mountDir')
    ..aOB(12, _omitFieldNames ? '' : 'canMount')
    ..aOS(13, _omitFieldNames ? '' : 'coreVersion')
    ..aOS(14, _omitFieldNames ? '' : 'coreBuild')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  State clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  State copyWith(void Function(State) updates) =>
      super.copyWith((message) => updates(message as State)) as State;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use State() / State.new instead')
  static State create() => State._();
  static $pb.GeneratedMessage $_createMessage() => State._();
  @$core.override
  State createEmptyInstance() => State._();
  @$core.pragma('dart2js:noInline')
  static State getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<State>(State.$_createMessage);
  static State? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get vaultExists => $_getBF(0);
  @$pb.TagNumber(1)
  set vaultExists($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVaultExists() => $_has(0);
  @$pb.TagNumber(1)
  void clearVaultExists() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get unlocked => $_getBF(1);
  @$pb.TagNumber(2)
  set unlocked($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnlocked() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnlocked() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get vaultPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set vaultPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVaultPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearVaultPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get vaultId => $_getSZ(3);
  @$pb.TagNumber(4)
  set vaultId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVaultId() => $_has(3);
  @$pb.TagNumber(4)
  void clearVaultId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get deviceId => $_getSZ(4);
  @$pb.TagNumber(5)
  set deviceId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeviceId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get deviceName => $_getSZ(5);
  @$pb.TagNumber(6)
  set deviceName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDeviceName() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get mountPoint => $_getSZ(6);
  @$pb.TagNumber(7)
  set mountPoint($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMountPoint() => $_has(6);
  @$pb.TagNumber(7)
  void clearMountPoint() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get platform => $_getSZ(7);
  @$pb.TagNumber(8)
  set platform($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPlatform() => $_has(7);
  @$pb.TagNumber(8)
  void clearPlatform() => $_clearField(8);

  /// Unlocked and working. Unlocked but not ready: the vault is open but the
  /// engine is not (too few storages for k+m, ...); problem says why. Storages
  /// can be added and k/m changed in that state.
  @$pb.TagNumber(9)
  $core.bool get ready => $_getBF(8);
  @$pb.TagNumber(9)
  set ready($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasReady() => $_has(8);
  @$pb.TagNumber(9)
  void clearReady() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get problem => $_getSZ(9);
  @$pb.TagNumber(10)
  set problem($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasProblem() => $_has(9);
  @$pb.TagNumber(10)
  void clearProblem() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get mountDir => $_getSZ(10);
  @$pb.TagNumber(11)
  set mountDir($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMountDir() => $_has(10);
  @$pb.TagNumber(11)
  void clearMountDir() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get canMount => $_getBF(11);
  @$pb.TagNumber(12)
  set canMount($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCanMount() => $_has(11);
  @$pb.TagNumber(12)
  void clearCanMount() => $_clearField(12);

  /// The core's build: the app shows it next to its own to spot a stale
  /// daemon (both come from one make run when built together).
  @$pb.TagNumber(13)
  $core.String get coreVersion => $_getSZ(12);
  @$pb.TagNumber(13)
  set coreVersion($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCoreVersion() => $_has(12);
  @$pb.TagNumber(13)
  void clearCoreVersion() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get coreBuild => $_getSZ(13);
  @$pb.TagNumber(14)
  set coreBuild($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCoreBuild() => $_has(13);
  @$pb.TagNumber(14)
  void clearCoreBuild() => $_clearField(14);
}

class CreateVaultRequest extends $pb.GeneratedMessage {
  factory CreateVaultRequest({
    $core.String? password,
    $core.int? dataShards,
    $core.int? parityShards,
    $core.String? deviceName,
  }) {
    final result = CreateVaultRequest._();
    if (password != null) result.password = password;
    if (dataShards != null) result.dataShards = dataShards;
    if (parityShards != null) result.parityShards = parityShards;
    if (deviceName != null) result.deviceName = deviceName;
    return result;
  }

  CreateVaultRequest._();

  factory CreateVaultRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateVaultRequest()..mergeFromBuffer(data, registry);
  factory CreateVaultRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateVaultRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateVaultRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: CreateVaultRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'password')
    ..aI(2, _omitFieldNames ? '' : 'dataShards')
    ..aI(3, _omitFieldNames ? '' : 'parityShards')
    ..aOS(4, _omitFieldNames ? '' : 'deviceName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateVaultRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateVaultRequest copyWith(void Function(CreateVaultRequest) updates) =>
      super.copyWith((message) => updates(message as CreateVaultRequest))
          as CreateVaultRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateVaultRequest() / CreateVaultRequest.new instead')
  static CreateVaultRequest create() => CreateVaultRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateVaultRequest._();
  @$core.override
  CreateVaultRequest createEmptyInstance() => CreateVaultRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateVaultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateVaultRequest>(
          CreateVaultRequest.$_createMessage);
  static CreateVaultRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get password => $_getSZ(0);
  @$pb.TagNumber(1)
  set password($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassword() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get dataShards => $_getIZ(1);
  @$pb.TagNumber(2)
  set dataShards($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDataShards() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataShards() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get parityShards => $_getIZ(2);
  @$pb.TagNumber(3)
  set parityShards($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParityShards() => $_has(2);
  @$pb.TagNumber(3)
  void clearParityShards() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get deviceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set deviceName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeviceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceName() => $_clearField(4);
}

class ImportVaultRequest extends $pb.GeneratedMessage {
  factory ImportVaultRequest({
    $core.List<$core.int>? vault,
    $core.String? password,
    $core.String? deviceName,
  }) {
    final result = ImportVaultRequest._();
    if (vault != null) result.vault = vault;
    if (password != null) result.password = password;
    if (deviceName != null) result.deviceName = deviceName;
    return result;
  }

  ImportVaultRequest._();

  factory ImportVaultRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImportVaultRequest()..mergeFromBuffer(data, registry);
  factory ImportVaultRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ImportVaultRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportVaultRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: ImportVaultRequest.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'vault', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOS(3, _omitFieldNames ? '' : 'deviceName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportVaultRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportVaultRequest copyWith(void Function(ImportVaultRequest) updates) =>
      super.copyWith((message) => updates(message as ImportVaultRequest))
          as ImportVaultRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ImportVaultRequest() / ImportVaultRequest.new instead')
  static ImportVaultRequest create() => ImportVaultRequest._();
  static $pb.GeneratedMessage $_createMessage() => ImportVaultRequest._();
  @$core.override
  ImportVaultRequest createEmptyInstance() => ImportVaultRequest._();
  @$core.pragma('dart2js:noInline')
  static ImportVaultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportVaultRequest>(
          ImportVaultRequest.$_createMessage);
  static ImportVaultRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get vault => $_getN(0);
  @$pb.TagNumber(1)
  set vault($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVault() => $_has(0);
  @$pb.TagNumber(1)
  void clearVault() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deviceName => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceName() => $_clearField(3);
}

class UnlockRequest extends $pb.GeneratedMessage {
  factory UnlockRequest({
    $core.String? password,
    $core.String? deviceName,
  }) {
    final result = UnlockRequest._();
    if (password != null) result.password = password;
    if (deviceName != null) result.deviceName = deviceName;
    return result;
  }

  UnlockRequest._();

  factory UnlockRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockRequest()..mergeFromBuffer(data, registry);
  factory UnlockRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnlockRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: UnlockRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'password')
    ..aOS(2, _omitFieldNames ? '' : 'deviceName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockRequest copyWith(void Function(UnlockRequest) updates) =>
      super.copyWith((message) => updates(message as UnlockRequest))
          as UnlockRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UnlockRequest() / UnlockRequest.new instead')
  static UnlockRequest create() => UnlockRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnlockRequest._();
  @$core.override
  UnlockRequest createEmptyInstance() => UnlockRequest._();
  @$core.pragma('dart2js:noInline')
  static UnlockRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UnlockRequest>(
          UnlockRequest.$_createMessage);
  static UnlockRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get password => $_getSZ(0);
  @$pb.TagNumber(1)
  set password($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassword() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceName() => $_clearField(2);
}

class ChangePasswordRequest extends $pb.GeneratedMessage {
  factory ChangePasswordRequest({
    $core.String? oldPassword,
    $core.String? newPassword,
  }) {
    final result = ChangePasswordRequest._();
    if (oldPassword != null) result.oldPassword = oldPassword;
    if (newPassword != null) result.newPassword = newPassword;
    return result;
  }

  ChangePasswordRequest._();

  factory ChangePasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordRequest()..mergeFromBuffer(data, registry);
  factory ChangePasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: ChangePasswordRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'oldPassword')
    ..aOS(2, _omitFieldNames ? '' : 'newPassword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest copyWith(
          void Function(ChangePasswordRequest) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordRequest))
          as ChangePasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangePasswordRequest() / ChangePasswordRequest.new instead')
  static ChangePasswordRequest create() => ChangePasswordRequest._();
  static $pb.GeneratedMessage $_createMessage() => ChangePasswordRequest._();
  @$core.override
  ChangePasswordRequest createEmptyInstance() => ChangePasswordRequest._();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordRequest>(
          ChangePasswordRequest.$_createMessage);
  static ChangePasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get oldPassword => $_getSZ(0);
  @$pb.TagNumber(1)
  set oldPassword($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOldPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearOldPassword() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPassword => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPassword($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPassword() => $_clearField(2);
}

class CheckPasswordRequest extends $pb.GeneratedMessage {
  factory CheckPasswordRequest({
    $core.String? password,
  }) {
    final result = CheckPasswordRequest._();
    if (password != null) result.password = password;
    return result;
  }

  CheckPasswordRequest._();

  factory CheckPasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckPasswordRequest()..mergeFromBuffer(data, registry);
  factory CheckPasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckPasswordRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckPasswordRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: CheckPasswordRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckPasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckPasswordRequest copyWith(void Function(CheckPasswordRequest) updates) =>
      super.copyWith((message) => updates(message as CheckPasswordRequest))
          as CheckPasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CheckPasswordRequest() / CheckPasswordRequest.new instead')
  static CheckPasswordRequest create() => CheckPasswordRequest._();
  static $pb.GeneratedMessage $_createMessage() => CheckPasswordRequest._();
  @$core.override
  CheckPasswordRequest createEmptyInstance() => CheckPasswordRequest._();
  @$core.pragma('dart2js:noInline')
  static CheckPasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckPasswordRequest>(
          CheckPasswordRequest.$_createMessage);
  static CheckPasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get password => $_getSZ(0);
  @$pb.TagNumber(1)
  set password($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassword() => $_clearField(1);
}

class VaultFile extends $pb.GeneratedMessage {
  factory VaultFile({
    $core.List<$core.int>? vault,
  }) {
    final result = VaultFile._();
    if (vault != null) result.vault = vault;
    return result;
  }

  VaultFile._();

  factory VaultFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VaultFile()..mergeFromBuffer(data, registry);
  factory VaultFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VaultFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VaultFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: VaultFile.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'vault', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VaultFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VaultFile copyWith(void Function(VaultFile) updates) =>
      super.copyWith((message) => updates(message as VaultFile)) as VaultFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VaultFile() / VaultFile.new instead')
  static VaultFile create() => VaultFile._();
  static $pb.GeneratedMessage $_createMessage() => VaultFile._();
  @$core.override
  VaultFile createEmptyInstance() => VaultFile._();
  @$core.pragma('dart2js:noInline')
  static VaultFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VaultFile>(VaultFile.$_createMessage);
  static VaultFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get vault => $_getN(0);
  @$pb.TagNumber(1)
  set vault($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVault() => $_has(0);
  @$pb.TagNumber(1)
  void clearVault() => $_clearField(1);
}

class BackendOption extends $pb.GeneratedMessage {
  factory BackendOption({
    $core.String? name,
    $core.String? help,
    $core.String? default_3,
    $core.bool? required,
    $core.bool? password,
    $core.bool? advanced,
    $core.Iterable<$core.String>? examples,
  }) {
    final result = BackendOption._();
    if (name != null) result.name = name;
    if (help != null) result.help = help;
    if (default_3 != null) result.default_3 = default_3;
    if (required != null) result.required = required;
    if (password != null) result.password = password;
    if (advanced != null) result.advanced = advanced;
    if (examples != null) result.examples.addAll(examples);
    return result;
  }

  BackendOption._();

  factory BackendOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BackendOption()..mergeFromBuffer(data, registry);
  factory BackendOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BackendOption()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackendOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: BackendOption.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'help')
    ..aOS(3, _omitFieldNames ? '' : 'default')
    ..aOB(4, _omitFieldNames ? '' : 'required')
    ..aOB(5, _omitFieldNames ? '' : 'password')
    ..aOB(6, _omitFieldNames ? '' : 'advanced')
    ..pPS(7, _omitFieldNames ? '' : 'examples')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendOption copyWith(void Function(BackendOption) updates) =>
      super.copyWith((message) => updates(message as BackendOption))
          as BackendOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BackendOption() / BackendOption.new instead')
  static BackendOption create() => BackendOption._();
  static $pb.GeneratedMessage $_createMessage() => BackendOption._();
  @$core.override
  BackendOption createEmptyInstance() => BackendOption._();
  @$core.pragma('dart2js:noInline')
  static BackendOption getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BackendOption>(
          BackendOption.$_createMessage);
  static BackendOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get help => $_getSZ(1);
  @$pb.TagNumber(2)
  set help($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHelp() => $_has(1);
  @$pb.TagNumber(2)
  void clearHelp() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get default_3 => $_getSZ(2);
  @$pb.TagNumber(3)
  set default_3($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDefault_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefault_3() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get required => $_getBF(3);
  @$pb.TagNumber(4)
  set required($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequired() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequired() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get password => $_getBF(4);
  @$pb.TagNumber(5)
  set password($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPassword() => $_has(4);
  @$pb.TagNumber(5)
  void clearPassword() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get advanced => $_getBF(5);
  @$pb.TagNumber(6)
  set advanced($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAdvanced() => $_has(5);
  @$pb.TagNumber(6)
  void clearAdvanced() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get examples => $_getList(6);
}

class BackendType extends $pb.GeneratedMessage {
  factory BackendType({
    $core.String? name,
    $core.String? description,
    $core.bool? oauth,
    $core.Iterable<BackendOption>? options,
  }) {
    final result = BackendType._();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (oauth != null) result.oauth = oauth;
    if (options != null) result.options.addAll(options);
    return result;
  }

  BackendType._();

  factory BackendType.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BackendType()..mergeFromBuffer(data, registry);
  factory BackendType.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BackendType()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackendType',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: BackendType.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOB(3, _omitFieldNames ? '' : 'oauth')
    ..pPM<BackendOption>(4, _omitFieldNames ? '' : 'options',
        subBuilder: BackendOption.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendType clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendType copyWith(void Function(BackendType) updates) =>
      super.copyWith((message) => updates(message as BackendType))
          as BackendType;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BackendType() / BackendType.new instead')
  static BackendType create() => BackendType._();
  static $pb.GeneratedMessage $_createMessage() => BackendType._();
  @$core.override
  BackendType createEmptyInstance() => BackendType._();
  @$core.pragma('dart2js:noInline')
  static BackendType getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BackendType>(
          BackendType.$_createMessage);
  static BackendType? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get oauth => $_getBF(2);
  @$pb.TagNumber(3)
  set oauth($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOauth() => $_has(2);
  @$pb.TagNumber(3)
  void clearOauth() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<BackendOption> get options => $_getList(3);
}

class BackendTypesReply extends $pb.GeneratedMessage {
  factory BackendTypesReply({
    $core.Iterable<BackendType>? types,
  }) {
    final result = BackendTypesReply._();
    if (types != null) result.types.addAll(types);
    return result;
  }

  BackendTypesReply._();

  factory BackendTypesReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BackendTypesReply()..mergeFromBuffer(data, registry);
  factory BackendTypesReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BackendTypesReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackendTypesReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: BackendTypesReply.$_createMessage)
    ..pPM<BackendType>(1, _omitFieldNames ? '' : 'types',
        subBuilder: BackendType.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendTypesReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendTypesReply copyWith(void Function(BackendTypesReply) updates) =>
      super.copyWith((message) => updates(message as BackendTypesReply))
          as BackendTypesReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BackendTypesReply() / BackendTypesReply.new instead')
  static BackendTypesReply create() => BackendTypesReply._();
  static $pb.GeneratedMessage $_createMessage() => BackendTypesReply._();
  @$core.override
  BackendTypesReply createEmptyInstance() => BackendTypesReply._();
  @$core.pragma('dart2js:noInline')
  static BackendTypesReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BackendTypesReply>(
          BackendTypesReply.$_createMessage);
  static BackendTypesReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BackendType> get types => $_getList(0);
}

class AddBackendRequest extends $pb.GeneratedMessage {
  factory AddBackendRequest({
    $core.String? name,
    $core.String? type,
    $core.String? domain,
    $core.String? root,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? params,
    $core.String? account,
  }) {
    final result = AddBackendRequest._();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (domain != null) result.domain = domain;
    if (root != null) result.root = root;
    if (params != null) result.params.addEntries(params);
    if (account != null) result.account = account;
    return result;
  }

  AddBackendRequest._();

  factory AddBackendRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddBackendRequest()..mergeFromBuffer(data, registry);
  factory AddBackendRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddBackendRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddBackendRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: AddBackendRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'domain')
    ..aOS(4, _omitFieldNames ? '' : 'root')
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'params',
        entryClassName: 'AddBackendRequest.ParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('cloudsync.v1'))
    ..aOS(6, _omitFieldNames ? '' : 'account')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddBackendRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddBackendRequest copyWith(void Function(AddBackendRequest) updates) =>
      super.copyWith((message) => updates(message as AddBackendRequest))
          as AddBackendRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddBackendRequest() / AddBackendRequest.new instead')
  static AddBackendRequest create() => AddBackendRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddBackendRequest._();
  @$core.override
  AddBackendRequest createEmptyInstance() => AddBackendRequest._();
  @$core.pragma('dart2js:noInline')
  static AddBackendRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddBackendRequest>(
          AddBackendRequest.$_createMessage);
  static AddBackendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get domain => $_getSZ(2);
  @$pb.TagNumber(3)
  set domain($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDomain() => $_has(2);
  @$pb.TagNumber(3)
  void clearDomain() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get root => $_getSZ(3);
  @$pb.TagNumber(4)
  set root($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRoot() => $_has(3);
  @$pb.TagNumber(4)
  void clearRoot() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, $core.String> get params => $_getMap(4);

  @$pb.TagNumber(6)
  $core.String get account => $_getSZ(5);
  @$pb.TagNumber(6)
  set account($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAccount() => $_has(5);
  @$pb.TagNumber(6)
  void clearAccount() => $_clearField(6);
}

class IdRequest extends $pb.GeneratedMessage {
  factory IdRequest({
    $core.String? id,
  }) {
    final result = IdRequest._();
    if (id != null) result.id = id;
    return result;
  }

  IdRequest._();

  factory IdRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdRequest()..mergeFromBuffer(data, registry);
  factory IdRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: IdRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdRequest copyWith(void Function(IdRequest) updates) =>
      super.copyWith((message) => updates(message as IdRequest)) as IdRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdRequest() / IdRequest.new instead')
  static IdRequest create() => IdRequest._();
  static $pb.GeneratedMessage $_createMessage() => IdRequest._();
  @$core.override
  IdRequest createEmptyInstance() => IdRequest._();
  @$core.pragma('dart2js:noInline')
  static IdRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IdRequest>(IdRequest.$_createMessage);
  static IdRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class RemoveBackendRequest extends $pb.GeneratedMessage {
  factory RemoveBackendRequest({
    $core.String? id,
    $core.bool? force,
  }) {
    final result = RemoveBackendRequest._();
    if (id != null) result.id = id;
    if (force != null) result.force = force;
    return result;
  }

  RemoveBackendRequest._();

  factory RemoveBackendRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveBackendRequest()..mergeFromBuffer(data, registry);
  factory RemoveBackendRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveBackendRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveBackendRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RemoveBackendRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'force')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveBackendRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveBackendRequest copyWith(void Function(RemoveBackendRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveBackendRequest))
          as RemoveBackendRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoveBackendRequest() / RemoveBackendRequest.new instead')
  static RemoveBackendRequest create() => RemoveBackendRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemoveBackendRequest._();
  @$core.override
  RemoveBackendRequest createEmptyInstance() => RemoveBackendRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoveBackendRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveBackendRequest>(
          RemoveBackendRequest.$_createMessage);
  static RemoveBackendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get force => $_getBF(1);
  @$pb.TagNumber(2)
  set force($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasForce() => $_has(1);
  @$pb.TagNumber(2)
  void clearForce() => $_clearField(2);
}

class AuthorizeRequest extends $pb.GeneratedMessage {
  factory AuthorizeRequest({
    $core.String? type,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? params,
  }) {
    final result = AuthorizeRequest._();
    if (type != null) result.type = type;
    if (params != null) result.params.addEntries(params);
    return result;
  }

  AuthorizeRequest._();

  factory AuthorizeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AuthorizeRequest()..mergeFromBuffer(data, registry);
  factory AuthorizeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AuthorizeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthorizeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: AuthorizeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'params',
        entryClassName: 'AuthorizeRequest.ParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('cloudsync.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeRequest copyWith(void Function(AuthorizeRequest) updates) =>
      super.copyWith((message) => updates(message as AuthorizeRequest))
          as AuthorizeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AuthorizeRequest() / AuthorizeRequest.new instead')
  static AuthorizeRequest create() => AuthorizeRequest._();
  static $pb.GeneratedMessage $_createMessage() => AuthorizeRequest._();
  @$core.override
  AuthorizeRequest createEmptyInstance() => AuthorizeRequest._();
  @$core.pragma('dart2js:noInline')
  static AuthorizeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AuthorizeRequest>(
          AuthorizeRequest.$_createMessage);
  static AuthorizeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get params => $_getMap(1);
}

class AuthorizeReply extends $pb.GeneratedMessage {
  factory AuthorizeReply({
    $core.String? url,
    $core.String? token,
    $core.String? account,
  }) {
    final result = AuthorizeReply._();
    if (url != null) result.url = url;
    if (token != null) result.token = token;
    if (account != null) result.account = account;
    return result;
  }

  AuthorizeReply._();

  factory AuthorizeReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AuthorizeReply()..mergeFromBuffer(data, registry);
  factory AuthorizeReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AuthorizeReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthorizeReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: AuthorizeReply.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOS(3, _omitFieldNames ? '' : 'account')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthorizeReply copyWith(void Function(AuthorizeReply) updates) =>
      super.copyWith((message) => updates(message as AuthorizeReply))
          as AuthorizeReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AuthorizeReply() / AuthorizeReply.new instead')
  static AuthorizeReply create() => AuthorizeReply._();
  static $pb.GeneratedMessage $_createMessage() => AuthorizeReply._();
  @$core.override
  AuthorizeReply createEmptyInstance() => AuthorizeReply._();
  @$core.pragma('dart2js:noInline')
  static AuthorizeReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AuthorizeReply>(
          AuthorizeReply.$_createMessage);
  static AuthorizeReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get account => $_getSZ(2);
  @$pb.TagNumber(3)
  set account($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAccount() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccount() => $_clearField(3);
}

class RenameBackendRequest extends $pb.GeneratedMessage {
  factory RenameBackendRequest({
    $core.String? id,
    $core.String? name,
  }) {
    final result = RenameBackendRequest._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  RenameBackendRequest._();

  factory RenameBackendRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameBackendRequest()..mergeFromBuffer(data, registry);
  factory RenameBackendRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameBackendRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameBackendRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RenameBackendRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameBackendRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameBackendRequest copyWith(void Function(RenameBackendRequest) updates) =>
      super.copyWith((message) => updates(message as RenameBackendRequest))
          as RenameBackendRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RenameBackendRequest() / RenameBackendRequest.new instead')
  static RenameBackendRequest create() => RenameBackendRequest._();
  static $pb.GeneratedMessage $_createMessage() => RenameBackendRequest._();
  @$core.override
  RenameBackendRequest createEmptyInstance() => RenameBackendRequest._();
  @$core.pragma('dart2js:noInline')
  static RenameBackendRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameBackendRequest>(
          RenameBackendRequest.$_createMessage);
  static RenameBackendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class SetBackendEnabledRequest extends $pb.GeneratedMessage {
  factory SetBackendEnabledRequest({
    $core.String? id,
    $core.bool? enabled,
  }) {
    final result = SetBackendEnabledRequest._();
    if (id != null) result.id = id;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetBackendEnabledRequest._();

  factory SetBackendEnabledRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetBackendEnabledRequest()..mergeFromBuffer(data, registry);
  factory SetBackendEnabledRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetBackendEnabledRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetBackendEnabledRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: SetBackendEnabledRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetBackendEnabledRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetBackendEnabledRequest copyWith(
          void Function(SetBackendEnabledRequest) updates) =>
      super.copyWith((message) => updates(message as SetBackendEnabledRequest))
          as SetBackendEnabledRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetBackendEnabledRequest() / SetBackendEnabledRequest.new instead')
  static SetBackendEnabledRequest create() => SetBackendEnabledRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetBackendEnabledRequest._();
  @$core.override
  SetBackendEnabledRequest createEmptyInstance() =>
      SetBackendEnabledRequest._();
  @$core.pragma('dart2js:noInline')
  static SetBackendEnabledRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetBackendEnabledRequest>(
          SetBackendEnabledRequest.$_createMessage);
  static SetBackendEnabledRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class Backend extends $pb.GeneratedMessage {
  factory Backend({
    $core.String? id,
    $core.String? name,
    $core.String? type,
    $core.String? domain,
    $core.bool? enabled,
    $core.bool? online,
    $core.bool? behind,
    $core.String? error,
    $core.String? account,
    $core.String? root,
    $core.String? sameAs,
    $core.bool? preparing,
    $fixnum.Int64? totalBytes,
    $fixnum.Int64? freeBytes,
    $fixnum.Int64? storedBytes,
    $core.int? getMs,
    $core.int? putMs,
    $core.int? listMs,
    $core.bool? oauth,
  }) {
    final result = Backend._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (domain != null) result.domain = domain;
    if (enabled != null) result.enabled = enabled;
    if (online != null) result.online = online;
    if (behind != null) result.behind = behind;
    if (error != null) result.error = error;
    if (account != null) result.account = account;
    if (root != null) result.root = root;
    if (sameAs != null) result.sameAs = sameAs;
    if (preparing != null) result.preparing = preparing;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (freeBytes != null) result.freeBytes = freeBytes;
    if (storedBytes != null) result.storedBytes = storedBytes;
    if (getMs != null) result.getMs = getMs;
    if (putMs != null) result.putMs = putMs;
    if (listMs != null) result.listMs = listMs;
    if (oauth != null) result.oauth = oauth;
    return result;
  }

  Backend._();

  factory Backend.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Backend()..mergeFromBuffer(data, registry);
  factory Backend.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Backend()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Backend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: Backend.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'domain')
    ..aOB(5, _omitFieldNames ? '' : 'enabled')
    ..aOB(6, _omitFieldNames ? '' : 'online')
    ..aOB(7, _omitFieldNames ? '' : 'behind')
    ..aOS(8, _omitFieldNames ? '' : 'error')
    ..aOS(9, _omitFieldNames ? '' : 'account')
    ..aOS(10, _omitFieldNames ? '' : 'root')
    ..aOS(11, _omitFieldNames ? '' : 'sameAs')
    ..aOB(12, _omitFieldNames ? '' : 'preparing')
    ..aInt64(13, _omitFieldNames ? '' : 'totalBytes')
    ..aInt64(14, _omitFieldNames ? '' : 'freeBytes')
    ..aInt64(15, _omitFieldNames ? '' : 'storedBytes')
    ..aI(16, _omitFieldNames ? '' : 'getMs')
    ..aI(17, _omitFieldNames ? '' : 'putMs')
    ..aI(18, _omitFieldNames ? '' : 'listMs')
    ..aOB(19, _omitFieldNames ? '' : 'oauth')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Backend clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Backend copyWith(void Function(Backend) updates) =>
      super.copyWith((message) => updates(message as Backend)) as Backend;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Backend() / Backend.new instead')
  static Backend create() => Backend._();
  static $pb.GeneratedMessage $_createMessage() => Backend._();
  @$core.override
  Backend createEmptyInstance() => Backend._();
  @$core.pragma('dart2js:noInline')
  static Backend getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Backend>(Backend.$_createMessage);
  static Backend? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get domain => $_getSZ(3);
  @$pb.TagNumber(4)
  set domain($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDomain() => $_has(3);
  @$pb.TagNumber(4)
  void clearDomain() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enabled => $_getBF(4);
  @$pb.TagNumber(5)
  set enabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnabled() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get online => $_getBF(5);
  @$pb.TagNumber(6)
  set online($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOnline() => $_has(5);
  @$pb.TagNumber(6)
  void clearOnline() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get behind => $_getBF(6);
  @$pb.TagNumber(7)
  set behind($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBehind() => $_has(6);
  @$pb.TagNumber(7)
  void clearBehind() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get error => $_getSZ(7);
  @$pb.TagNumber(8)
  set error($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(8)
  void clearError() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get account => $_getSZ(8);
  @$pb.TagNumber(9)
  set account($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAccount() => $_has(8);
  @$pb.TagNumber(9)
  void clearAccount() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get root => $_getSZ(9);
  @$pb.TagNumber(10)
  set root($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRoot() => $_has(9);
  @$pb.TagNumber(10)
  void clearRoot() => $_clearField(10);

  /// Id of another storage in the same place (same account or folder): one
  /// of them should go, it adds no redundancy.
  @$pb.TagNumber(11)
  $core.String get sameAs => $_getSZ(10);
  @$pb.TagNumber(11)
  set sameAs($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSameAs() => $_has(10);
  @$pb.TagNumber(11)
  void clearSameAs() => $_clearField(11);

  /// In the vault, not yet opened by the engine (just added; it reopens).
  @$pb.TagNumber(12)
  $core.bool get preparing => $_getBF(11);
  @$pb.TagNumber(12)
  set preparing($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPreparing() => $_has(11);
  @$pb.TagNumber(12)
  void clearPreparing() => $_clearField(12);

  /// Space of the account in bytes, set when the provider reports it (not
  /// every one does; an offline storage cannot).
  @$pb.TagNumber(13)
  $fixnum.Int64 get totalBytes => $_getI64(12);
  @$pb.TagNumber(13)
  set totalBytes($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTotalBytes() => $_has(12);
  @$pb.TagNumber(13)
  void clearTotalBytes() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get freeBytes => $_getI64(13);
  @$pb.TagNumber(14)
  set freeBytes($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasFreeBytes() => $_has(13);
  @$pb.TagNumber(14)
  void clearFreeBytes() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get storedBytes => $_getI64(14);
  @$pb.TagNumber(15)
  set storedBytes($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasStoredBytes() => $_has(14);
  @$pb.TagNumber(15)
  void clearStoredBytes() => $_clearField(15);

  /// Recent response time of a read, a write and a listing in milliseconds
  /// (smoothed; 0 until this device made such a call).
  @$pb.TagNumber(16)
  $core.int get getMs => $_getIZ(15);
  @$pb.TagNumber(16)
  set getMs($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasGetMs() => $_has(15);
  @$pb.TagNumber(16)
  void clearGetMs() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.int get putMs => $_getIZ(16);
  @$pb.TagNumber(17)
  set putMs($core.int value) => $_setSignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasPutMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearPutMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get listMs => $_getIZ(17);
  @$pb.TagNumber(18)
  set listMs($core.int value) => $_setSignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasListMs() => $_has(17);
  @$pb.TagNumber(18)
  void clearListMs() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get oauth => $_getBF(18);
  @$pb.TagNumber(19)
  set oauth($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasOauth() => $_has(18);
  @$pb.TagNumber(19)
  void clearOauth() => $_clearField(19);
}

class Device extends $pb.GeneratedMessage {
  factory Device({
    $core.String? id,
    $core.String? name,
    $core.String? platform,
    $fixnum.Int64? addedUnix,
  }) {
    final result = Device._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (platform != null) result.platform = platform;
    if (addedUnix != null) result.addedUnix = addedUnix;
    return result;
  }

  Device._();

  factory Device.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Device()..mergeFromBuffer(data, registry);
  factory Device.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Device()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Device',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: Device.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'platform')
    ..aInt64(4, _omitFieldNames ? '' : 'addedUnix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Device clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Device copyWith(void Function(Device) updates) =>
      super.copyWith((message) => updates(message as Device)) as Device;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Device() / Device.new instead')
  static Device create() => Device._();
  static $pb.GeneratedMessage $_createMessage() => Device._();
  @$core.override
  Device createEmptyInstance() => Device._();
  @$core.pragma('dart2js:noInline')
  static Device getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Device>(Device.$_createMessage);
  static Device? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get platform => $_getSZ(2);
  @$pb.TagNumber(3)
  set platform($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatform() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get addedUnix => $_getI64(3);
  @$pb.TagNumber(4)
  set addedUnix($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAddedUnix() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddedUnix() => $_clearField(4);
}

class StatusReply extends $pb.GeneratedMessage {
  factory StatusReply({
    $core.int? dataShards,
    $core.int? parityShards,
    $core.Iterable<Backend>? backends,
    $core.Iterable<Device>? devices,
    $core.int? pending,
    $core.bool? reloadNeeded,
    $core.bool? domainRisk,
    $fixnum.Int64? cacheBytes,
    $core.Iterable<$core.String>? pins,
    $core.String? deviceId,
    $fixnum.Int64? vaultVersion,
    $fixnum.Int64? filesBytes,
    $fixnum.Int64? writableBytes,
  }) {
    final result = StatusReply._();
    if (dataShards != null) result.dataShards = dataShards;
    if (parityShards != null) result.parityShards = parityShards;
    if (backends != null) result.backends.addAll(backends);
    if (devices != null) result.devices.addAll(devices);
    if (pending != null) result.pending = pending;
    if (reloadNeeded != null) result.reloadNeeded = reloadNeeded;
    if (domainRisk != null) result.domainRisk = domainRisk;
    if (cacheBytes != null) result.cacheBytes = cacheBytes;
    if (pins != null) result.pins.addAll(pins);
    if (deviceId != null) result.deviceId = deviceId;
    if (vaultVersion != null) result.vaultVersion = vaultVersion;
    if (filesBytes != null) result.filesBytes = filesBytes;
    if (writableBytes != null) result.writableBytes = writableBytes;
    return result;
  }

  StatusReply._();

  factory StatusReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusReply()..mergeFromBuffer(data, registry);
  factory StatusReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: StatusReply.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'dataShards')
    ..aI(2, _omitFieldNames ? '' : 'parityShards')
    ..pPM<Backend>(3, _omitFieldNames ? '' : 'backends',
        subBuilder: Backend.$_createMessage)
    ..pPM<Device>(4, _omitFieldNames ? '' : 'devices',
        subBuilder: Device.$_createMessage)
    ..aI(5, _omitFieldNames ? '' : 'pending')
    ..aOB(6, _omitFieldNames ? '' : 'reloadNeeded')
    ..aOB(7, _omitFieldNames ? '' : 'domainRisk')
    ..aInt64(8, _omitFieldNames ? '' : 'cacheBytes')
    ..pPS(9, _omitFieldNames ? '' : 'pins')
    ..aOS(10, _omitFieldNames ? '' : 'deviceId')
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'vaultVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(12, _omitFieldNames ? '' : 'filesBytes')
    ..aInt64(13, _omitFieldNames ? '' : 'writableBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusReply copyWith(void Function(StatusReply) updates) =>
      super.copyWith((message) => updates(message as StatusReply))
          as StatusReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatusReply() / StatusReply.new instead')
  static StatusReply create() => StatusReply._();
  static $pb.GeneratedMessage $_createMessage() => StatusReply._();
  @$core.override
  StatusReply createEmptyInstance() => StatusReply._();
  @$core.pragma('dart2js:noInline')
  static StatusReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusReply>(
          StatusReply.$_createMessage);
  static StatusReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get dataShards => $_getIZ(0);
  @$pb.TagNumber(1)
  set dataShards($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDataShards() => $_has(0);
  @$pb.TagNumber(1)
  void clearDataShards() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get parityShards => $_getIZ(1);
  @$pb.TagNumber(2)
  set parityShards($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParityShards() => $_has(1);
  @$pb.TagNumber(2)
  void clearParityShards() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Backend> get backends => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<Device> get devices => $_getList(3);

  @$pb.TagNumber(5)
  $core.int get pending => $_getIZ(4);
  @$pb.TagNumber(5)
  set pending($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPending() => $_has(4);
  @$pb.TagNumber(5)
  void clearPending() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get reloadNeeded => $_getBF(5);
  @$pb.TagNumber(6)
  set reloadNeeded($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReloadNeeded() => $_has(5);
  @$pb.TagNumber(6)
  void clearReloadNeeded() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get domainRisk => $_getBF(6);
  @$pb.TagNumber(7)
  set domainRisk($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDomainRisk() => $_has(6);
  @$pb.TagNumber(7)
  void clearDomainRisk() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get cacheBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set cacheBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCacheBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearCacheBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get pins => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get deviceId => $_getSZ(9);
  @$pb.TagNumber(10)
  set deviceId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDeviceId() => $_has(9);
  @$pb.TagNumber(10)
  void clearDeviceId() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get vaultVersion => $_getI64(10);
  @$pb.TagNumber(11)
  set vaultVersion($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasVaultVersion() => $_has(10);
  @$pb.TagNumber(11)
  void clearVaultVersion() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get filesBytes => $_getI64(11);
  @$pb.TagNumber(12)
  set filesBytes($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasFilesBytes() => $_has(11);
  @$pb.TagNumber(12)
  void clearFilesBytes() => $_clearField(12);

  /// More file bytes that fit with full redundancy (until the first storage
  /// new data goes to is full). Unset: no storage reports its space.
  /// Storages that do not report are taken as unlimited.
  @$pb.TagNumber(13)
  $fixnum.Int64 get writableBytes => $_getI64(12);
  @$pb.TagNumber(13)
  set writableBytes($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasWritableBytes() => $_has(12);
  @$pb.TagNumber(13)
  void clearWritableBytes() => $_clearField(13);
}

class PathRequest extends $pb.GeneratedMessage {
  factory PathRequest({
    $core.String? path,
  }) {
    final result = PathRequest._();
    if (path != null) result.path = path;
    return result;
  }

  PathRequest._();

  factory PathRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathRequest()..mergeFromBuffer(data, registry);
  factory PathRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PathRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: PathRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathRequest copyWith(void Function(PathRequest) updates) =>
      super.copyWith((message) => updates(message as PathRequest))
          as PathRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PathRequest() / PathRequest.new instead')
  static PathRequest create() => PathRequest._();
  static $pb.GeneratedMessage $_createMessage() => PathRequest._();
  @$core.override
  PathRequest createEmptyInstance() => PathRequest._();
  @$core.pragma('dart2js:noInline')
  static PathRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PathRequest>(
          PathRequest.$_createMessage);
  static PathRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class PathsRequest extends $pb.GeneratedMessage {
  factory PathsRequest({
    $core.Iterable<$core.String>? paths,
  }) {
    final result = PathsRequest._();
    if (paths != null) result.paths.addAll(paths);
    return result;
  }

  PathsRequest._();

  factory PathsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathsRequest()..mergeFromBuffer(data, registry);
  factory PathsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PathsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PathsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: PathsRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PathsRequest copyWith(void Function(PathsRequest) updates) =>
      super.copyWith((message) => updates(message as PathsRequest))
          as PathsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PathsRequest() / PathsRequest.new instead')
  static PathsRequest create() => PathsRequest._();
  static $pb.GeneratedMessage $_createMessage() => PathsRequest._();
  @$core.override
  PathsRequest createEmptyInstance() => PathsRequest._();
  @$core.pragma('dart2js:noInline')
  static PathsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PathsRequest>(
          PathsRequest.$_createMessage);
  static PathsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get paths => $_getList(0);
}

class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? query,
    $core.int? limit,
  }) {
    final result = SearchRequest._();
    if (query != null) result.query = query;
    if (limit != null) result.limit = limit;
    return result;
  }

  SearchRequest._();

  factory SearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchRequest()..mergeFromBuffer(data, registry);
  factory SearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SearchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: SearchRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest copyWith(void Function(SearchRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRequest))
          as SearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SearchRequest() / SearchRequest.new instead')
  static SearchRequest create() => SearchRequest._();
  static $pb.GeneratedMessage $_createMessage() => SearchRequest._();
  @$core.override
  SearchRequest createEmptyInstance() => SearchRequest._();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchRequest>(
          SearchRequest.$_createMessage);
  static SearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class Entry extends $pb.GeneratedMessage {
  factory Entry({
    $core.String? path,
    $core.String? name,
    $core.bool? dir,
    $fixnum.Int64? size,
    $fixnum.Int64? mtimeUnix,
    $core.bool? local,
    $core.bool? pinned,
    $core.String? device,
    $core.String? conflictOf,
  }) {
    final result = Entry._();
    if (path != null) result.path = path;
    if (name != null) result.name = name;
    if (dir != null) result.dir = dir;
    if (size != null) result.size = size;
    if (mtimeUnix != null) result.mtimeUnix = mtimeUnix;
    if (local != null) result.local = local;
    if (pinned != null) result.pinned = pinned;
    if (device != null) result.device = device;
    if (conflictOf != null) result.conflictOf = conflictOf;
    return result;
  }

  Entry._();

  factory Entry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Entry()..mergeFromBuffer(data, registry);
  factory Entry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Entry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Entry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: Entry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'dir')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..aInt64(5, _omitFieldNames ? '' : 'mtimeUnix')
    ..aOB(6, _omitFieldNames ? '' : 'local')
    ..aOB(7, _omitFieldNames ? '' : 'pinned')
    ..aOS(8, _omitFieldNames ? '' : 'device')
    ..aOS(9, _omitFieldNames ? '' : 'conflictOf')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Entry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Entry copyWith(void Function(Entry) updates) =>
      super.copyWith((message) => updates(message as Entry)) as Entry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Entry() / Entry.new instead')
  static Entry create() => Entry._();
  static $pb.GeneratedMessage $_createMessage() => Entry._();
  @$core.override
  Entry createEmptyInstance() => Entry._();
  @$core.pragma('dart2js:noInline')
  static Entry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Entry>(Entry.$_createMessage);
  static Entry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get dir => $_getBF(2);
  @$pb.TagNumber(3)
  set dir($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearDir() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get mtimeUnix => $_getI64(4);
  @$pb.TagNumber(5)
  set mtimeUnix($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMtimeUnix() => $_has(4);
  @$pb.TagNumber(5)
  void clearMtimeUnix() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get local => $_getBF(5);
  @$pb.TagNumber(6)
  set local($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLocal() => $_has(5);
  @$pb.TagNumber(6)
  void clearLocal() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get pinned => $_getBF(6);
  @$pb.TagNumber(7)
  set pinned($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPinned() => $_has(6);
  @$pb.TagNumber(7)
  void clearPinned() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get device => $_getSZ(7);
  @$pb.TagNumber(8)
  set device($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDevice() => $_has(7);
  @$pb.TagNumber(8)
  void clearDevice() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get conflictOf => $_getSZ(8);
  @$pb.TagNumber(9)
  set conflictOf($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasConflictOf() => $_has(8);
  @$pb.TagNumber(9)
  void clearConflictOf() => $_clearField(9);
}

class ListReply extends $pb.GeneratedMessage {
  factory ListReply({
    $core.Iterable<Entry>? entries,
  }) {
    final result = ListReply._();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  ListReply._();

  factory ListReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListReply()..mergeFromBuffer(data, registry);
  factory ListReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: ListReply.$_createMessage)
    ..pPM<Entry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: Entry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReply copyWith(void Function(ListReply) updates) =>
      super.copyWith((message) => updates(message as ListReply)) as ListReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListReply() / ListReply.new instead')
  static ListReply create() => ListReply._();
  static $pb.GeneratedMessage $_createMessage() => ListReply._();
  @$core.override
  ListReply createEmptyInstance() => ListReply._();
  @$core.pragma('dart2js:noInline')
  static ListReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReply>(ListReply.$_createMessage);
  static ListReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Entry> get entries => $_getList(0);
}

class RemoveRequest extends $pb.GeneratedMessage {
  factory RemoveRequest({
    $core.String? path,
    $core.bool? recursive,
  }) {
    final result = RemoveRequest._();
    if (path != null) result.path = path;
    if (recursive != null) result.recursive = recursive;
    return result;
  }

  RemoveRequest._();

  factory RemoveRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveRequest()..mergeFromBuffer(data, registry);
  factory RemoveRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoveRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RemoveRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOB(2, _omitFieldNames ? '' : 'recursive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveRequest copyWith(void Function(RemoveRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveRequest))
          as RemoveRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoveRequest() / RemoveRequest.new instead')
  static RemoveRequest create() => RemoveRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemoveRequest._();
  @$core.override
  RemoveRequest createEmptyInstance() => RemoveRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoveRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoveRequest>(
          RemoveRequest.$_createMessage);
  static RemoveRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get recursive => $_getBF(1);
  @$pb.TagNumber(2)
  set recursive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRecursive() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecursive() => $_clearField(2);
}

class RenameRequest extends $pb.GeneratedMessage {
  factory RenameRequest({
    $core.String? from,
    $core.String? to,
  }) {
    final result = RenameRequest._();
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    return result;
  }

  RenameRequest._();

  factory RenameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameRequest()..mergeFromBuffer(data, registry);
  factory RenameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RenameRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RenameRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'from')
    ..aOS(2, _omitFieldNames ? '' : 'to')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest copyWith(void Function(RenameRequest) updates) =>
      super.copyWith((message) => updates(message as RenameRequest))
          as RenameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RenameRequest() / RenameRequest.new instead')
  static RenameRequest create() => RenameRequest._();
  static $pb.GeneratedMessage $_createMessage() => RenameRequest._();
  @$core.override
  RenameRequest createEmptyInstance() => RenameRequest._();
  @$core.pragma('dart2js:noInline')
  static RenameRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RenameRequest>(
          RenameRequest.$_createMessage);
  static RenameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get from => $_getSZ(0);
  @$pb.TagNumber(1)
  set from($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get to => $_getSZ(1);
  @$pb.TagNumber(2)
  set to($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => $_clearField(2);
}

class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    $core.Iterable<$core.String>? localPaths,
    $core.String? remoteDir,
  }) {
    final result = UploadRequest._();
    if (localPaths != null) result.localPaths.addAll(localPaths);
    if (remoteDir != null) result.remoteDir = remoteDir;
    return result;
  }

  UploadRequest._();

  factory UploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadRequest()..mergeFromBuffer(data, registry);
  factory UploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: UploadRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'localPaths')
    ..aOS(2, _omitFieldNames ? '' : 'remoteDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest copyWith(void Function(UploadRequest) updates) =>
      super.copyWith((message) => updates(message as UploadRequest))
          as UploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadRequest() / UploadRequest.new instead')
  static UploadRequest create() => UploadRequest._();
  static $pb.GeneratedMessage $_createMessage() => UploadRequest._();
  @$core.override
  UploadRequest createEmptyInstance() => UploadRequest._();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadRequest>(
          UploadRequest.$_createMessage);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get localPaths => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get remoteDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set remoteDir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRemoteDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemoteDir() => $_clearField(2);
}

class UploadReply extends $pb.GeneratedMessage {
  factory UploadReply({
    $core.int? files,
  }) {
    final result = UploadReply._();
    if (files != null) result.files = files;
    return result;
  }

  UploadReply._();

  factory UploadReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadReply()..mergeFromBuffer(data, registry);
  factory UploadReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: UploadReply.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'files')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadReply copyWith(void Function(UploadReply) updates) =>
      super.copyWith((message) => updates(message as UploadReply))
          as UploadReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadReply() / UploadReply.new instead')
  static UploadReply create() => UploadReply._();
  static $pb.GeneratedMessage $_createMessage() => UploadReply._();
  @$core.override
  UploadReply createEmptyInstance() => UploadReply._();
  @$core.pragma('dart2js:noInline')
  static UploadReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadReply>(
          UploadReply.$_createMessage);
  static UploadReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get files => $_getIZ(0);
  @$pb.TagNumber(1)
  set files($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFiles() => $_has(0);
  @$pb.TagNumber(1)
  void clearFiles() => $_clearField(1);
}

class DownloadRequest extends $pb.GeneratedMessage {
  factory DownloadRequest({
    $core.String? path,
    $core.String? localPath,
  }) {
    final result = DownloadRequest._();
    if (path != null) result.path = path;
    if (localPath != null) result.localPath = localPath;
    return result;
  }

  DownloadRequest._();

  factory DownloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadRequest()..mergeFromBuffer(data, registry);
  factory DownloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: DownloadRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'localPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest copyWith(void Function(DownloadRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadRequest))
          as DownloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DownloadRequest() / DownloadRequest.new instead')
  static DownloadRequest create() => DownloadRequest._();
  static $pb.GeneratedMessage $_createMessage() => DownloadRequest._();
  @$core.override
  DownloadRequest createEmptyInstance() => DownloadRequest._();
  @$core.pragma('dart2js:noInline')
  static DownloadRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DownloadRequest>(
          DownloadRequest.$_createMessage);
  static DownloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get localPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set localPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalPath() => $_clearField(2);
}

class LockInfo extends $pb.GeneratedMessage {
  factory LockInfo({
    $core.bool? locked,
    $core.String? deviceId,
    $core.String? deviceName,
    $fixnum.Int64? sinceUnix,
    $core.bool? mine,
    $core.String? path,
  }) {
    final result = LockInfo._();
    if (locked != null) result.locked = locked;
    if (deviceId != null) result.deviceId = deviceId;
    if (deviceName != null) result.deviceName = deviceName;
    if (sinceUnix != null) result.sinceUnix = sinceUnix;
    if (mine != null) result.mine = mine;
    if (path != null) result.path = path;
    return result;
  }

  LockInfo._();

  factory LockInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LockInfo()..mergeFromBuffer(data, registry);
  factory LockInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LockInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LockInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: LockInfo.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'locked')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'deviceName')
    ..aInt64(4, _omitFieldNames ? '' : 'sinceUnix')
    ..aOB(5, _omitFieldNames ? '' : 'mine')
    ..aOS(6, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockInfo copyWith(void Function(LockInfo) updates) =>
      super.copyWith((message) => updates(message as LockInfo)) as LockInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LockInfo() / LockInfo.new instead')
  static LockInfo create() => LockInfo._();
  static $pb.GeneratedMessage $_createMessage() => LockInfo._();
  @$core.override
  LockInfo createEmptyInstance() => LockInfo._();
  @$core.pragma('dart2js:noInline')
  static LockInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LockInfo>(LockInfo.$_createMessage);
  static LockInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get locked => $_getBF(0);
  @$pb.TagNumber(1)
  set locked($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLocked() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocked() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get deviceName => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sinceUnix => $_getI64(3);
  @$pb.TagNumber(4)
  set sinceUnix($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSinceUnix() => $_has(3);
  @$pb.TagNumber(4)
  void clearSinceUnix() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get mine => $_getBF(4);
  @$pb.TagNumber(5)
  set mine($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMine() => $_has(4);
  @$pb.TagNumber(5)
  void clearMine() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get path => $_getSZ(5);
  @$pb.TagNumber(6)
  set path($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPath() => $_has(5);
  @$pb.TagNumber(6)
  void clearPath() => $_clearField(6);
}

class LocksReply extends $pb.GeneratedMessage {
  factory LocksReply({
    $core.Iterable<LockInfo>? locks,
  }) {
    final result = LocksReply._();
    if (locks != null) result.locks.addAll(locks);
    return result;
  }

  LocksReply._();

  factory LocksReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocksReply()..mergeFromBuffer(data, registry);
  factory LocksReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocksReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocksReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: LocksReply.$_createMessage)
    ..pPM<LockInfo>(1, _omitFieldNames ? '' : 'locks',
        subBuilder: LockInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocksReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocksReply copyWith(void Function(LocksReply) updates) =>
      super.copyWith((message) => updates(message as LocksReply)) as LocksReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LocksReply() / LocksReply.new instead')
  static LocksReply create() => LocksReply._();
  static $pb.GeneratedMessage $_createMessage() => LocksReply._();
  @$core.override
  LocksReply createEmptyInstance() => LocksReply._();
  @$core.pragma('dart2js:noInline')
  static LocksReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocksReply>(LocksReply.$_createMessage);
  static LocksReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LockInfo> get locks => $_getList(0);
}

class RepairRequest extends $pb.GeneratedMessage {
  factory RepairRequest({
    $core.bool? rebalance,
  }) {
    final result = RepairRequest._();
    if (rebalance != null) result.rebalance = rebalance;
    return result;
  }

  RepairRequest._();

  factory RepairRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RepairRequest()..mergeFromBuffer(data, registry);
  factory RepairRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RepairRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RepairRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RepairRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'rebalance')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepairRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepairRequest copyWith(void Function(RepairRequest) updates) =>
      super.copyWith((message) => updates(message as RepairRequest))
          as RepairRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RepairRequest() / RepairRequest.new instead')
  static RepairRequest create() => RepairRequest._();
  static $pb.GeneratedMessage $_createMessage() => RepairRequest._();
  @$core.override
  RepairRequest createEmptyInstance() => RepairRequest._();
  @$core.pragma('dart2js:noInline')
  static RepairRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepairRequest>(
          RepairRequest.$_createMessage);
  static RepairRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get rebalance => $_getBF(0);
  @$pb.TagNumber(1)
  set rebalance($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRebalance() => $_has(0);
  @$pb.TagNumber(1)
  void clearRebalance() => $_clearField(1);
}

class RepairReply extends $pb.GeneratedMessage {
  factory RepairReply({
    $core.int? blobs,
    $core.int? repaired,
    $core.int? failed,
    $core.int? journalCopies,
    $core.int? reencoded,
    $core.int? moved,
    $core.Iterable<$core.String>? damaged,
    $core.int? fromLocal,
  }) {
    final result = RepairReply._();
    if (blobs != null) result.blobs = blobs;
    if (repaired != null) result.repaired = repaired;
    if (failed != null) result.failed = failed;
    if (journalCopies != null) result.journalCopies = journalCopies;
    if (reencoded != null) result.reencoded = reencoded;
    if (moved != null) result.moved = moved;
    if (damaged != null) result.damaged.addAll(damaged);
    if (fromLocal != null) result.fromLocal = fromLocal;
    return result;
  }

  RepairReply._();

  factory RepairReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RepairReply()..mergeFromBuffer(data, registry);
  factory RepairReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RepairReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RepairReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RepairReply.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'blobs')
    ..aI(2, _omitFieldNames ? '' : 'repaired')
    ..aI(3, _omitFieldNames ? '' : 'failed')
    ..aI(4, _omitFieldNames ? '' : 'journalCopies')
    ..aI(5, _omitFieldNames ? '' : 'reencoded')
    ..aI(6, _omitFieldNames ? '' : 'moved')
    ..pPS(7, _omitFieldNames ? '' : 'damaged')
    ..aI(8, _omitFieldNames ? '' : 'fromLocal')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepairReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RepairReply copyWith(void Function(RepairReply) updates) =>
      super.copyWith((message) => updates(message as RepairReply))
          as RepairReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RepairReply() / RepairReply.new instead')
  static RepairReply create() => RepairReply._();
  static $pb.GeneratedMessage $_createMessage() => RepairReply._();
  @$core.override
  RepairReply createEmptyInstance() => RepairReply._();
  @$core.pragma('dart2js:noInline')
  static RepairReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepairReply>(
          RepairReply.$_createMessage);
  static RepairReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get blobs => $_getIZ(0);
  @$pb.TagNumber(1)
  set blobs($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBlobs() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlobs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get repaired => $_getIZ(1);
  @$pb.TagNumber(2)
  set repaired($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepaired() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepaired() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get failed => $_getIZ(2);
  @$pb.TagNumber(3)
  set failed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFailed() => $_has(2);
  @$pb.TagNumber(3)
  void clearFailed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get journalCopies => $_getIZ(3);
  @$pb.TagNumber(4)
  set journalCopies($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasJournalCopies() => $_has(3);
  @$pb.TagNumber(4)
  void clearJournalCopies() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get reencoded => $_getIZ(4);
  @$pb.TagNumber(5)
  set reencoded($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReencoded() => $_has(4);
  @$pb.TagNumber(5)
  void clearReencoded() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get moved => $_getIZ(5);
  @$pb.TagNumber(6)
  set moved($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMoved() => $_has(5);
  @$pb.TagNumber(6)
  void clearMoved() => $_clearField(6);

  /// Files using a blob that could not be repaired: parts of them cannot be
  /// read now.
  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get damaged => $_getList(6);

  @$pb.TagNumber(8)
  $core.int get fromLocal => $_getIZ(7);
  @$pb.TagNumber(8)
  set fromLocal($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFromLocal() => $_has(7);
  @$pb.TagNumber(8)
  void clearFromLocal() => $_clearField(8);
}

class GCRequest extends $pb.GeneratedMessage {
  factory GCRequest({
    $fixnum.Int64? graceSeconds,
  }) {
    final result = GCRequest._();
    if (graceSeconds != null) result.graceSeconds = graceSeconds;
    return result;
  }

  GCRequest._();

  factory GCRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GCRequest()..mergeFromBuffer(data, registry);
  factory GCRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GCRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GCRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: GCRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'graceSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GCRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GCRequest copyWith(void Function(GCRequest) updates) =>
      super.copyWith((message) => updates(message as GCRequest)) as GCRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GCRequest() / GCRequest.new instead')
  static GCRequest create() => GCRequest._();
  static $pb.GeneratedMessage $_createMessage() => GCRequest._();
  @$core.override
  GCRequest createEmptyInstance() => GCRequest._();
  @$core.pragma('dart2js:noInline')
  static GCRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GCRequest>(GCRequest.$_createMessage);
  static GCRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get graceSeconds => $_getI64(0);
  @$pb.TagNumber(1)
  set graceSeconds($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGraceSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearGraceSeconds() => $_clearField(1);
}

class GCReply extends $pb.GeneratedMessage {
  factory GCReply({
    $core.int? objects,
    $core.int? unused,
    $core.int? deleted,
    $core.Iterable<$core.String>? skipped,
  }) {
    final result = GCReply._();
    if (objects != null) result.objects = objects;
    if (unused != null) result.unused = unused;
    if (deleted != null) result.deleted = deleted;
    if (skipped != null) result.skipped.addAll(skipped);
    return result;
  }

  GCReply._();

  factory GCReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GCReply()..mergeFromBuffer(data, registry);
  factory GCReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GCReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GCReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: GCReply.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'objects')
    ..aI(2, _omitFieldNames ? '' : 'unused')
    ..aI(3, _omitFieldNames ? '' : 'deleted')
    ..pPS(4, _omitFieldNames ? '' : 'skipped')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GCReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GCReply copyWith(void Function(GCReply) updates) =>
      super.copyWith((message) => updates(message as GCReply)) as GCReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GCReply() / GCReply.new instead')
  static GCReply create() => GCReply._();
  static $pb.GeneratedMessage $_createMessage() => GCReply._();
  @$core.override
  GCReply createEmptyInstance() => GCReply._();
  @$core.pragma('dart2js:noInline')
  static GCReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GCReply>(GCReply.$_createMessage);
  static GCReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get objects => $_getIZ(0);
  @$pb.TagNumber(1)
  set objects($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjects() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjects() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get unused => $_getIZ(1);
  @$pb.TagNumber(2)
  set unused($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnused() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnused() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get deleted => $_getIZ(2);
  @$pb.TagNumber(3)
  set deleted($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeleted() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeleted() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get skipped => $_getList(3);
}

class SetRedundancyRequest extends $pb.GeneratedMessage {
  factory SetRedundancyRequest({
    $core.int? dataShards,
    $core.int? parityShards,
  }) {
    final result = SetRedundancyRequest._();
    if (dataShards != null) result.dataShards = dataShards;
    if (parityShards != null) result.parityShards = parityShards;
    return result;
  }

  SetRedundancyRequest._();

  factory SetRedundancyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRedundancyRequest()..mergeFromBuffer(data, registry);
  factory SetRedundancyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRedundancyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRedundancyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: SetRedundancyRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'dataShards')
    ..aI(2, _omitFieldNames ? '' : 'parityShards')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRedundancyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRedundancyRequest copyWith(void Function(SetRedundancyRequest) updates) =>
      super.copyWith((message) => updates(message as SetRedundancyRequest))
          as SetRedundancyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetRedundancyRequest() / SetRedundancyRequest.new instead')
  static SetRedundancyRequest create() => SetRedundancyRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetRedundancyRequest._();
  @$core.override
  SetRedundancyRequest createEmptyInstance() => SetRedundancyRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRedundancyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRedundancyRequest>(
          SetRedundancyRequest.$_createMessage);
  static SetRedundancyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get dataShards => $_getIZ(0);
  @$pb.TagNumber(1)
  set dataShards($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDataShards() => $_has(0);
  @$pb.TagNumber(1)
  void clearDataShards() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get parityShards => $_getIZ(1);
  @$pb.TagNumber(2)
  set parityShards($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParityShards() => $_has(1);
  @$pb.TagNumber(2)
  void clearParityShards() => $_clearField(2);
}

class Event extends $pb.GeneratedMessage {
  factory Event({
    Event_Kind? kind,
    $core.String? message,
  }) {
    final result = Event._();
    if (kind != null) result.kind = kind;
    if (message != null) result.message = message;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..aE<Event_Kind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: Event_Kind.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(1)
  Event_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(Event_Kind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class LogsRequest extends $pb.GeneratedMessage {
  factory LogsRequest({
    $core.String? backendId,
    $core.int? limit,
  }) {
    final result = LogsRequest._();
    if (backendId != null) result.backendId = backendId;
    if (limit != null) result.limit = limit;
    return result;
  }

  LogsRequest._();

  factory LogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogsRequest()..mergeFromBuffer(data, registry);
  factory LogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: LogsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'backendId')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogsRequest copyWith(void Function(LogsRequest) updates) =>
      super.copyWith((message) => updates(message as LogsRequest))
          as LogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogsRequest() / LogsRequest.new instead')
  static LogsRequest create() => LogsRequest._();
  static $pb.GeneratedMessage $_createMessage() => LogsRequest._();
  @$core.override
  LogsRequest createEmptyInstance() => LogsRequest._();
  @$core.pragma('dart2js:noInline')
  static LogsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogsRequest>(
          LogsRequest.$_createMessage);
  static LogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get backendId => $_getSZ(0);
  @$pb.TagNumber(1)
  set backendId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBackendId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBackendId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class LogEntry extends $pb.GeneratedMessage {
  factory LogEntry({
    $fixnum.Int64? seq,
    $fixnum.Int64? timeUnixMs,
    $fixnum.Int64? firstUnixMs,
    $core.String? level,
    $core.String? source,
    $core.String? backendId,
    $core.String? message,
    $core.int? count,
  }) {
    final result = LogEntry._();
    if (seq != null) result.seq = seq;
    if (timeUnixMs != null) result.timeUnixMs = timeUnixMs;
    if (firstUnixMs != null) result.firstUnixMs = firstUnixMs;
    if (level != null) result.level = level;
    if (source != null) result.source = source;
    if (backendId != null) result.backendId = backendId;
    if (message != null) result.message = message;
    if (count != null) result.count = count;
    return result;
  }

  LogEntry._();

  factory LogEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogEntry()..mergeFromBuffer(data, registry);
  factory LogEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: LogEntry.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(2, _omitFieldNames ? '' : 'timeUnixMs')
    ..aInt64(3, _omitFieldNames ? '' : 'firstUnixMs')
    ..aOS(4, _omitFieldNames ? '' : 'level')
    ..aOS(5, _omitFieldNames ? '' : 'source')
    ..aOS(6, _omitFieldNames ? '' : 'backendId')
    ..aOS(7, _omitFieldNames ? '' : 'message')
    ..aI(8, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry copyWith(void Function(LogEntry) updates) =>
      super.copyWith((message) => updates(message as LogEntry)) as LogEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogEntry() / LogEntry.new instead')
  static LogEntry create() => LogEntry._();
  static $pb.GeneratedMessage $_createMessage() => LogEntry._();
  @$core.override
  LogEntry createEmptyInstance() => LogEntry._();
  @$core.pragma('dart2js:noInline')
  static LogEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogEntry>(LogEntry.$_createMessage);
  static LogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timeUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set timeUnixMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimeUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeUnixMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get firstUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set firstUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFirstUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearFirstUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get level => $_getSZ(3);
  @$pb.TagNumber(4)
  set level($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLevel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLevel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get source => $_getSZ(4);
  @$pb.TagNumber(5)
  set source($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearSource() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get backendId => $_getSZ(5);
  @$pb.TagNumber(6)
  set backendId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBackendId() => $_has(5);
  @$pb.TagNumber(6)
  void clearBackendId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get message => $_getSZ(6);
  @$pb.TagNumber(7)
  set message($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessage() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get count => $_getIZ(7);
  @$pb.TagNumber(8)
  set count($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearCount() => $_clearField(8);
}

class LogsReply extends $pb.GeneratedMessage {
  factory LogsReply({
    $core.Iterable<LogEntry>? entries,
  }) {
    final result = LogsReply._();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  LogsReply._();

  factory LogsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogsReply()..mergeFromBuffer(data, registry);
  factory LogsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogsReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogsReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: LogsReply.$_createMessage)
    ..pPM<LogEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: LogEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogsReply copyWith(void Function(LogsReply) updates) =>
      super.copyWith((message) => updates(message as LogsReply)) as LogsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogsReply() / LogsReply.new instead')
  static LogsReply create() => LogsReply._();
  static $pb.GeneratedMessage $_createMessage() => LogsReply._();
  @$core.override
  LogsReply createEmptyInstance() => LogsReply._();
  @$core.pragma('dart2js:noInline')
  static LogsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogsReply>(LogsReply.$_createMessage);
  static LogsReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LogEntry> get entries => $_getList(0);
}

class SecretEntry extends $pb.GeneratedMessage {
  factory SecretEntry({
    $core.String? id,
    $core.String? version,
    SecretKind? kind,
    $core.String? title,
    $core.String? groupId,
    $core.String? username,
    $core.String? url,
    $core.String? comment,
    Web3Network? network,
    $core.String? keyType,
    $core.String? publicKey,
    $core.String? fingerprint,
    $core.String? address,
    $fixnum.Int64? createdUnix,
    $fixnum.Int64? updatedUnix,
    $core.String? device,
    $core.String? conflictOf,
    $core.int? recoveryLeft,
    $core.bool? opened,
    $core.String? password,
    $core.String? notes,
    $core.String? privateKey,
    $core.String? passphrase,
    $core.String? totpSecret,
    $core.String? totpAlgorithm,
    $core.int? totpDigits,
    $core.int? totpPeriod,
    $core.Iterable<$core.String>? recoveryCodes,
  }) {
    final result = SecretEntry._();
    if (id != null) result.id = id;
    if (version != null) result.version = version;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (groupId != null) result.groupId = groupId;
    if (username != null) result.username = username;
    if (url != null) result.url = url;
    if (comment != null) result.comment = comment;
    if (network != null) result.network = network;
    if (keyType != null) result.keyType = keyType;
    if (publicKey != null) result.publicKey = publicKey;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (address != null) result.address = address;
    if (createdUnix != null) result.createdUnix = createdUnix;
    if (updatedUnix != null) result.updatedUnix = updatedUnix;
    if (device != null) result.device = device;
    if (conflictOf != null) result.conflictOf = conflictOf;
    if (recoveryLeft != null) result.recoveryLeft = recoveryLeft;
    if (opened != null) result.opened = opened;
    if (password != null) result.password = password;
    if (notes != null) result.notes = notes;
    if (privateKey != null) result.privateKey = privateKey;
    if (passphrase != null) result.passphrase = passphrase;
    if (totpSecret != null) result.totpSecret = totpSecret;
    if (totpAlgorithm != null) result.totpAlgorithm = totpAlgorithm;
    if (totpDigits != null) result.totpDigits = totpDigits;
    if (totpPeriod != null) result.totpPeriod = totpPeriod;
    if (recoveryCodes != null) result.recoveryCodes.addAll(recoveryCodes);
    return result;
  }

  SecretEntry._();

  factory SecretEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretEntry()..mergeFromBuffer(data, registry);
  factory SecretEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SecretEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: SecretEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aE<SecretKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: SecretKind.values)
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'groupId')
    ..aOS(6, _omitFieldNames ? '' : 'username')
    ..aOS(7, _omitFieldNames ? '' : 'url')
    ..aOS(8, _omitFieldNames ? '' : 'comment')
    ..aE<Web3Network>(9, _omitFieldNames ? '' : 'network',
        enumValues: Web3Network.values)
    ..aOS(10, _omitFieldNames ? '' : 'keyType')
    ..aOS(11, _omitFieldNames ? '' : 'publicKey')
    ..aOS(12, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(13, _omitFieldNames ? '' : 'address')
    ..aInt64(14, _omitFieldNames ? '' : 'createdUnix')
    ..aInt64(15, _omitFieldNames ? '' : 'updatedUnix')
    ..aOS(16, _omitFieldNames ? '' : 'device')
    ..aOS(17, _omitFieldNames ? '' : 'conflictOf')
    ..aI(18, _omitFieldNames ? '' : 'recoveryLeft')
    ..aOB(20, _omitFieldNames ? '' : 'opened')
    ..aOS(21, _omitFieldNames ? '' : 'password')
    ..aOS(22, _omitFieldNames ? '' : 'notes')
    ..aOS(23, _omitFieldNames ? '' : 'privateKey')
    ..aOS(24, _omitFieldNames ? '' : 'passphrase')
    ..aOS(25, _omitFieldNames ? '' : 'totpSecret')
    ..aOS(26, _omitFieldNames ? '' : 'totpAlgorithm')
    ..aI(27, _omitFieldNames ? '' : 'totpDigits')
    ..aI(28, _omitFieldNames ? '' : 'totpPeriod')
    ..pPS(29, _omitFieldNames ? '' : 'recoveryCodes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretEntry copyWith(void Function(SecretEntry) updates) =>
      super.copyWith((message) => updates(message as SecretEntry))
          as SecretEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SecretEntry() / SecretEntry.new instead')
  static SecretEntry create() => SecretEntry._();
  static $pb.GeneratedMessage $_createMessage() => SecretEntry._();
  @$core.override
  SecretEntry createEmptyInstance() => SecretEntry._();
  @$core.pragma('dart2js:noInline')
  static SecretEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SecretEntry>(
          SecretEntry.$_createMessage);
  static SecretEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Version the client edited (from GetSecret); a change made meanwhile on
  /// another device is kept as a conflict copy instead of being replaced.
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  SecretKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(SecretKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get groupId => $_getSZ(4);
  @$pb.TagNumber(5)
  set groupId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGroupId() => $_has(4);
  @$pb.TagNumber(5)
  void clearGroupId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get username => $_getSZ(5);
  @$pb.TagNumber(6)
  set username($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUsername() => $_has(5);
  @$pb.TagNumber(6)
  void clearUsername() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get url => $_getSZ(6);
  @$pb.TagNumber(7)
  set url($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUrl() => $_has(6);
  @$pb.TagNumber(7)
  void clearUrl() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get comment => $_getSZ(7);
  @$pb.TagNumber(8)
  set comment($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasComment() => $_has(7);
  @$pb.TagNumber(8)
  void clearComment() => $_clearField(8);

  @$pb.TagNumber(9)
  Web3Network get network => $_getN(8);
  @$pb.TagNumber(9)
  set network(Web3Network value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasNetwork() => $_has(8);
  @$pb.TagNumber(9)
  void clearNetwork() => $_clearField(9);

  /// Derived by the core from the private key (read only).
  @$pb.TagNumber(10)
  $core.String get keyType => $_getSZ(9);
  @$pb.TagNumber(10)
  set keyType($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasKeyType() => $_has(9);
  @$pb.TagNumber(10)
  void clearKeyType() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get publicKey => $_getSZ(10);
  @$pb.TagNumber(11)
  set publicKey($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPublicKey() => $_has(10);
  @$pb.TagNumber(11)
  void clearPublicKey() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get fingerprint => $_getSZ(11);
  @$pb.TagNumber(12)
  set fingerprint($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasFingerprint() => $_has(11);
  @$pb.TagNumber(12)
  void clearFingerprint() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get address => $_getSZ(12);
  @$pb.TagNumber(13)
  set address($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasAddress() => $_has(12);
  @$pb.TagNumber(13)
  void clearAddress() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get createdUnix => $_getI64(13);
  @$pb.TagNumber(14)
  set createdUnix($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCreatedUnix() => $_has(13);
  @$pb.TagNumber(14)
  void clearCreatedUnix() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get updatedUnix => $_getI64(14);
  @$pb.TagNumber(15)
  set updatedUnix($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasUpdatedUnix() => $_has(14);
  @$pb.TagNumber(15)
  void clearUpdatedUnix() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get device => $_getSZ(15);
  @$pb.TagNumber(16)
  set device($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasDevice() => $_has(15);
  @$pb.TagNumber(16)
  void clearDevice() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get conflictOf => $_getSZ(16);
  @$pb.TagNumber(17)
  set conflictOf($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasConflictOf() => $_has(16);
  @$pb.TagNumber(17)
  void clearConflictOf() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get recoveryLeft => $_getIZ(17);
  @$pb.TagNumber(18)
  set recoveryLeft($core.int value) => $_setSignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasRecoveryLeft() => $_has(17);
  @$pb.TagNumber(18)
  void clearRecoveryLeft() => $_clearField(18);

  /// Secret fields: only in GetSecret replies and PutSecret requests.
  @$pb.TagNumber(20)
  $core.bool get opened => $_getBF(18);
  @$pb.TagNumber(20)
  set opened($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(20)
  $core.bool hasOpened() => $_has(18);
  @$pb.TagNumber(20)
  void clearOpened() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get password => $_getSZ(19);
  @$pb.TagNumber(21)
  set password($core.String value) => $_setString(19, value);
  @$pb.TagNumber(21)
  $core.bool hasPassword() => $_has(19);
  @$pb.TagNumber(21)
  void clearPassword() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get notes => $_getSZ(20);
  @$pb.TagNumber(22)
  set notes($core.String value) => $_setString(20, value);
  @$pb.TagNumber(22)
  $core.bool hasNotes() => $_has(20);
  @$pb.TagNumber(22)
  void clearNotes() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get privateKey => $_getSZ(21);
  @$pb.TagNumber(23)
  set privateKey($core.String value) => $_setString(21, value);
  @$pb.TagNumber(23)
  $core.bool hasPrivateKey() => $_has(21);
  @$pb.TagNumber(23)
  void clearPrivateKey() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get passphrase => $_getSZ(22);
  @$pb.TagNumber(24)
  set passphrase($core.String value) => $_setString(22, value);
  @$pb.TagNumber(24)
  $core.bool hasPassphrase() => $_has(22);
  @$pb.TagNumber(24)
  void clearPassphrase() => $_clearField(24);

  /// TOTP. In PutSecret the secret may be an otpauth:// URI (its parameters
  /// then win); GetSecret returns the base32 key. 0 / "" = default.
  @$pb.TagNumber(25)
  $core.String get totpSecret => $_getSZ(23);
  @$pb.TagNumber(25)
  set totpSecret($core.String value) => $_setString(23, value);
  @$pb.TagNumber(25)
  $core.bool hasTotpSecret() => $_has(23);
  @$pb.TagNumber(25)
  void clearTotpSecret() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.String get totpAlgorithm => $_getSZ(24);
  @$pb.TagNumber(26)
  set totpAlgorithm($core.String value) => $_setString(24, value);
  @$pb.TagNumber(26)
  $core.bool hasTotpAlgorithm() => $_has(24);
  @$pb.TagNumber(26)
  void clearTotpAlgorithm() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.int get totpDigits => $_getIZ(25);
  @$pb.TagNumber(27)
  set totpDigits($core.int value) => $_setSignedInt32(25, value);
  @$pb.TagNumber(27)
  $core.bool hasTotpDigits() => $_has(25);
  @$pb.TagNumber(27)
  void clearTotpDigits() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.int get totpPeriod => $_getIZ(26);
  @$pb.TagNumber(28)
  set totpPeriod($core.int value) => $_setSignedInt32(26, value);
  @$pb.TagNumber(28)
  $core.bool hasTotpPeriod() => $_has(26);
  @$pb.TagNumber(28)
  void clearTotpPeriod() => $_clearField(28);

  /// PutSecret: pasted text is parsed into codes (any element may hold many).
  @$pb.TagNumber(29)
  $pb.PbList<$core.String> get recoveryCodes => $_getList(27);
}

class SecretGroup extends $pb.GeneratedMessage {
  factory SecretGroup({
    $core.String? id,
    $core.String? name,
    $core.List<$core.int>? icon,
    $core.String? conflictOf,
  }) {
    final result = SecretGroup._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (icon != null) result.icon = icon;
    if (conflictOf != null) result.conflictOf = conflictOf;
    return result;
  }

  SecretGroup._();

  factory SecretGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretGroup()..mergeFromBuffer(data, registry);
  factory SecretGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretGroup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SecretGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: SecretGroup.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'icon', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'conflictOf')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretGroup copyWith(void Function(SecretGroup) updates) =>
      super.copyWith((message) => updates(message as SecretGroup))
          as SecretGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SecretGroup() / SecretGroup.new instead')
  static SecretGroup create() => SecretGroup._();
  static $pb.GeneratedMessage $_createMessage() => SecretGroup._();
  @$core.override
  SecretGroup createEmptyInstance() => SecretGroup._();
  @$core.pragma('dart2js:noInline')
  static SecretGroup getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SecretGroup>(
          SecretGroup.$_createMessage);
  static SecretGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get icon => $_getN(2);
  @$pb.TagNumber(3)
  set icon($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIcon() => $_has(2);
  @$pb.TagNumber(3)
  void clearIcon() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get conflictOf => $_getSZ(3);
  @$pb.TagNumber(4)
  set conflictOf($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConflictOf() => $_has(3);
  @$pb.TagNumber(4)
  void clearConflictOf() => $_clearField(4);
}

class SecretsReply extends $pb.GeneratedMessage {
  factory SecretsReply({
    $core.Iterable<SecretGroup>? groups,
    $core.Iterable<SecretEntry>? entries,
    $core.int? broken,
  }) {
    final result = SecretsReply._();
    if (groups != null) result.groups.addAll(groups);
    if (entries != null) result.entries.addAll(entries);
    if (broken != null) result.broken = broken;
    return result;
  }

  SecretsReply._();

  factory SecretsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretsReply()..mergeFromBuffer(data, registry);
  factory SecretsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretsReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SecretsReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: SecretsReply.$_createMessage)
    ..pPM<SecretGroup>(1, _omitFieldNames ? '' : 'groups',
        subBuilder: SecretGroup.$_createMessage)
    ..pPM<SecretEntry>(2, _omitFieldNames ? '' : 'entries',
        subBuilder: SecretEntry.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'broken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretsReply copyWith(void Function(SecretsReply) updates) =>
      super.copyWith((message) => updates(message as SecretsReply))
          as SecretsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SecretsReply() / SecretsReply.new instead')
  static SecretsReply create() => SecretsReply._();
  static $pb.GeneratedMessage $_createMessage() => SecretsReply._();
  @$core.override
  SecretsReply createEmptyInstance() => SecretsReply._();
  @$core.pragma('dart2js:noInline')
  static SecretsReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SecretsReply>(
          SecretsReply.$_createMessage);
  static SecretsReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SecretGroup> get groups => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<SecretEntry> get entries => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get broken => $_getIZ(2);
  @$pb.TagNumber(3)
  set broken($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBroken() => $_has(2);
  @$pb.TagNumber(3)
  void clearBroken() => $_clearField(3);
}

class DeriveKeyRequest extends $pb.GeneratedMessage {
  factory DeriveKeyRequest({
    SecretKind? kind,
    Web3Network? network,
    $core.String? privateKey,
    $core.String? passphrase,
    $core.String? comment,
  }) {
    final result = DeriveKeyRequest._();
    if (kind != null) result.kind = kind;
    if (network != null) result.network = network;
    if (privateKey != null) result.privateKey = privateKey;
    if (passphrase != null) result.passphrase = passphrase;
    if (comment != null) result.comment = comment;
    return result;
  }

  DeriveKeyRequest._();

  factory DeriveKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeriveKeyRequest()..mergeFromBuffer(data, registry);
  factory DeriveKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeriveKeyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeriveKeyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: DeriveKeyRequest.$_createMessage)
    ..aE<SecretKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: SecretKind.values)
    ..aE<Web3Network>(2, _omitFieldNames ? '' : 'network',
        enumValues: Web3Network.values)
    ..aOS(3, _omitFieldNames ? '' : 'privateKey')
    ..aOS(4, _omitFieldNames ? '' : 'passphrase')
    ..aOS(5, _omitFieldNames ? '' : 'comment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeriveKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeriveKeyRequest copyWith(void Function(DeriveKeyRequest) updates) =>
      super.copyWith((message) => updates(message as DeriveKeyRequest))
          as DeriveKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeriveKeyRequest() / DeriveKeyRequest.new instead')
  static DeriveKeyRequest create() => DeriveKeyRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeriveKeyRequest._();
  @$core.override
  DeriveKeyRequest createEmptyInstance() => DeriveKeyRequest._();
  @$core.pragma('dart2js:noInline')
  static DeriveKeyRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeriveKeyRequest>(
          DeriveKeyRequest.$_createMessage);
  static DeriveKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SecretKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(SecretKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  Web3Network get network => $_getN(1);
  @$pb.TagNumber(2)
  set network(Web3Network value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNetwork() => $_has(1);
  @$pb.TagNumber(2)
  void clearNetwork() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get privateKey => $_getSZ(2);
  @$pb.TagNumber(3)
  set privateKey($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrivateKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrivateKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get passphrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set passphrase($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPassphrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassphrase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get comment => $_getSZ(4);
  @$pb.TagNumber(5)
  set comment($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasComment() => $_has(4);
  @$pb.TagNumber(5)
  void clearComment() => $_clearField(5);
}

class DerivedKey extends $pb.GeneratedMessage {
  factory DerivedKey({
    $core.String? keyType,
    $core.String? publicKey,
    $core.String? fingerprint,
    $core.String? address,
  }) {
    final result = DerivedKey._();
    if (keyType != null) result.keyType = keyType;
    if (publicKey != null) result.publicKey = publicKey;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (address != null) result.address = address;
    return result;
  }

  DerivedKey._();

  factory DerivedKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DerivedKey()..mergeFromBuffer(data, registry);
  factory DerivedKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DerivedKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DerivedKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: DerivedKey.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'keyType')
    ..aOS(2, _omitFieldNames ? '' : 'publicKey')
    ..aOS(3, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(4, _omitFieldNames ? '' : 'address')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DerivedKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DerivedKey copyWith(void Function(DerivedKey) updates) =>
      super.copyWith((message) => updates(message as DerivedKey)) as DerivedKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DerivedKey() / DerivedKey.new instead')
  static DerivedKey create() => DerivedKey._();
  static $pb.GeneratedMessage $_createMessage() => DerivedKey._();
  @$core.override
  DerivedKey createEmptyInstance() => DerivedKey._();
  @$core.pragma('dart2js:noInline')
  static DerivedKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DerivedKey>(DerivedKey.$_createMessage);
  static DerivedKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get keyType => $_getSZ(0);
  @$pb.TagNumber(1)
  set keyType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyType() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get publicKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set publicKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublicKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fingerprint => $_getSZ(2);
  @$pb.TagNumber(3)
  set fingerprint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFingerprint() => $_has(2);
  @$pb.TagNumber(3)
  void clearFingerprint() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get address => $_getSZ(3);
  @$pb.TagNumber(4)
  set address($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAddress() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddress() => $_clearField(4);
}

class TotpCode extends $pb.GeneratedMessage {
  factory TotpCode({
    $core.String? id,
    $core.String? code,
    $core.String? next,
    $core.int? period,
    $fixnum.Int64? expiresUnix,
  }) {
    final result = TotpCode._();
    if (id != null) result.id = id;
    if (code != null) result.code = code;
    if (next != null) result.next = next;
    if (period != null) result.period = period;
    if (expiresUnix != null) result.expiresUnix = expiresUnix;
    return result;
  }

  TotpCode._();

  factory TotpCode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TotpCode()..mergeFromBuffer(data, registry);
  factory TotpCode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TotpCode()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TotpCode',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: TotpCode.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOS(3, _omitFieldNames ? '' : 'next')
    ..aI(4, _omitFieldNames ? '' : 'period')
    ..aInt64(5, _omitFieldNames ? '' : 'expiresUnix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TotpCode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TotpCode copyWith(void Function(TotpCode) updates) =>
      super.copyWith((message) => updates(message as TotpCode)) as TotpCode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TotpCode() / TotpCode.new instead')
  static TotpCode create() => TotpCode._();
  static $pb.GeneratedMessage $_createMessage() => TotpCode._();
  @$core.override
  TotpCode createEmptyInstance() => TotpCode._();
  @$core.pragma('dart2js:noInline')
  static TotpCode getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TotpCode>(TotpCode.$_createMessage);
  static TotpCode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get next => $_getSZ(2);
  @$pb.TagNumber(3)
  set next($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNext() => $_has(2);
  @$pb.TagNumber(3)
  void clearNext() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get period => $_getIZ(3);
  @$pb.TagNumber(4)
  set period($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPeriod() => $_has(3);
  @$pb.TagNumber(4)
  void clearPeriod() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get expiresUnix => $_getI64(4);
  @$pb.TagNumber(5)
  set expiresUnix($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpiresUnix() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpiresUnix() => $_clearField(5);
}

class TotpCodesReply extends $pb.GeneratedMessage {
  factory TotpCodesReply({
    $core.Iterable<TotpCode>? codes,
    $fixnum.Int64? nowUnix,
  }) {
    final result = TotpCodesReply._();
    if (codes != null) result.codes.addAll(codes);
    if (nowUnix != null) result.nowUnix = nowUnix;
    return result;
  }

  TotpCodesReply._();

  factory TotpCodesReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TotpCodesReply()..mergeFromBuffer(data, registry);
  factory TotpCodesReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TotpCodesReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TotpCodesReply',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: TotpCodesReply.$_createMessage)
    ..pPM<TotpCode>(1, _omitFieldNames ? '' : 'codes',
        subBuilder: TotpCode.$_createMessage)
    ..aInt64(2, _omitFieldNames ? '' : 'nowUnix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TotpCodesReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TotpCodesReply copyWith(void Function(TotpCodesReply) updates) =>
      super.copyWith((message) => updates(message as TotpCodesReply))
          as TotpCodesReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TotpCodesReply() / TotpCodesReply.new instead')
  static TotpCodesReply create() => TotpCodesReply._();
  static $pb.GeneratedMessage $_createMessage() => TotpCodesReply._();
  @$core.override
  TotpCodesReply createEmptyInstance() => TotpCodesReply._();
  @$core.pragma('dart2js:noInline')
  static TotpCodesReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TotpCodesReply>(
          TotpCodesReply.$_createMessage);
  static TotpCodesReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TotpCode> get codes => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get nowUnix => $_getI64(1);
  @$pb.TagNumber(2)
  set nowUnix($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNowUnix() => $_has(1);
  @$pb.TagNumber(2)
  void clearNowUnix() => $_clearField(2);
}

class RecoveryCodeRequest extends $pb.GeneratedMessage {
  factory RecoveryCodeRequest({
    $core.String? id,
    $core.String? code,
  }) {
    final result = RecoveryCodeRequest._();
    if (id != null) result.id = id;
    if (code != null) result.code = code;
    return result;
  }

  RecoveryCodeRequest._();

  factory RecoveryCodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecoveryCodeRequest()..mergeFromBuffer(data, registry);
  factory RecoveryCodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecoveryCodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecoveryCodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: RecoveryCodeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecoveryCodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecoveryCodeRequest copyWith(void Function(RecoveryCodeRequest) updates) =>
      super.copyWith((message) => updates(message as RecoveryCodeRequest))
          as RecoveryCodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RecoveryCodeRequest() / RecoveryCodeRequest.new instead')
  static RecoveryCodeRequest create() => RecoveryCodeRequest._();
  static $pb.GeneratedMessage $_createMessage() => RecoveryCodeRequest._();
  @$core.override
  RecoveryCodeRequest createEmptyInstance() => RecoveryCodeRequest._();
  @$core.pragma('dart2js:noInline')
  static RecoveryCodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecoveryCodeRequest>(
          RecoveryCodeRequest.$_createMessage);
  static RecoveryCodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);
}

class CheckTotpRequest extends $pb.GeneratedMessage {
  factory CheckTotpRequest({
    $core.String? secret,
    $core.String? algorithm,
    $core.int? digits,
    $core.int? period,
    $core.String? recoveryText,
  }) {
    final result = CheckTotpRequest._();
    if (secret != null) result.secret = secret;
    if (algorithm != null) result.algorithm = algorithm;
    if (digits != null) result.digits = digits;
    if (period != null) result.period = period;
    if (recoveryText != null) result.recoveryText = recoveryText;
    return result;
  }

  CheckTotpRequest._();

  factory CheckTotpRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckTotpRequest()..mergeFromBuffer(data, registry);
  factory CheckTotpRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckTotpRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckTotpRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: CheckTotpRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'secret')
    ..aOS(2, _omitFieldNames ? '' : 'algorithm')
    ..aI(3, _omitFieldNames ? '' : 'digits')
    ..aI(4, _omitFieldNames ? '' : 'period')
    ..aOS(5, _omitFieldNames ? '' : 'recoveryText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckTotpRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckTotpRequest copyWith(void Function(CheckTotpRequest) updates) =>
      super.copyWith((message) => updates(message as CheckTotpRequest))
          as CheckTotpRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CheckTotpRequest() / CheckTotpRequest.new instead')
  static CheckTotpRequest create() => CheckTotpRequest._();
  static $pb.GeneratedMessage $_createMessage() => CheckTotpRequest._();
  @$core.override
  CheckTotpRequest createEmptyInstance() => CheckTotpRequest._();
  @$core.pragma('dart2js:noInline')
  static CheckTotpRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckTotpRequest>(
          CheckTotpRequest.$_createMessage);
  static CheckTotpRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get secret => $_getSZ(0);
  @$pb.TagNumber(1)
  set secret($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get algorithm => $_getSZ(1);
  @$pb.TagNumber(2)
  set algorithm($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAlgorithm() => $_has(1);
  @$pb.TagNumber(2)
  void clearAlgorithm() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get digits => $_getIZ(2);
  @$pb.TagNumber(3)
  set digits($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDigits() => $_has(2);
  @$pb.TagNumber(3)
  void clearDigits() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get period => $_getIZ(3);
  @$pb.TagNumber(4)
  set period($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPeriod() => $_has(3);
  @$pb.TagNumber(4)
  void clearPeriod() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get recoveryText => $_getSZ(4);
  @$pb.TagNumber(5)
  set recoveryText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRecoveryText() => $_has(4);
  @$pb.TagNumber(5)
  void clearRecoveryText() => $_clearField(5);
}

class TotpPreview extends $pb.GeneratedMessage {
  factory TotpPreview({
    $core.String? issuer,
    $core.String? account,
    $core.String? algorithm,
    $core.int? digits,
    $core.int? period,
    $core.String? code,
    $core.Iterable<$core.String>? recoveryCodes,
    $core.String? error,
  }) {
    final result = TotpPreview._();
    if (issuer != null) result.issuer = issuer;
    if (account != null) result.account = account;
    if (algorithm != null) result.algorithm = algorithm;
    if (digits != null) result.digits = digits;
    if (period != null) result.period = period;
    if (code != null) result.code = code;
    if (recoveryCodes != null) result.recoveryCodes.addAll(recoveryCodes);
    if (error != null) result.error = error;
    return result;
  }

  TotpPreview._();

  factory TotpPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TotpPreview()..mergeFromBuffer(data, registry);
  factory TotpPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TotpPreview()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TotpPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cloudsync.v1'),
      createEmptyInstance: TotpPreview.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'issuer')
    ..aOS(2, _omitFieldNames ? '' : 'account')
    ..aOS(3, _omitFieldNames ? '' : 'algorithm')
    ..aI(4, _omitFieldNames ? '' : 'digits')
    ..aI(5, _omitFieldNames ? '' : 'period')
    ..aOS(6, _omitFieldNames ? '' : 'code')
    ..pPS(7, _omitFieldNames ? '' : 'recoveryCodes')
    ..aOS(8, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TotpPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TotpPreview copyWith(void Function(TotpPreview) updates) =>
      super.copyWith((message) => updates(message as TotpPreview))
          as TotpPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TotpPreview() / TotpPreview.new instead')
  static TotpPreview create() => TotpPreview._();
  static $pb.GeneratedMessage $_createMessage() => TotpPreview._();
  @$core.override
  TotpPreview createEmptyInstance() => TotpPreview._();
  @$core.pragma('dart2js:noInline')
  static TotpPreview getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TotpPreview>(
          TotpPreview.$_createMessage);
  static TotpPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get issuer => $_getSZ(0);
  @$pb.TagNumber(1)
  set issuer($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIssuer() => $_has(0);
  @$pb.TagNumber(1)
  void clearIssuer() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get account => $_getSZ(1);
  @$pb.TagNumber(2)
  set account($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get algorithm => $_getSZ(2);
  @$pb.TagNumber(3)
  set algorithm($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAlgorithm() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlgorithm() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get digits => $_getIZ(3);
  @$pb.TagNumber(4)
  set digits($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDigits() => $_has(3);
  @$pb.TagNumber(4)
  void clearDigits() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get period => $_getIZ(4);
  @$pb.TagNumber(5)
  set period($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPeriod() => $_has(4);
  @$pb.TagNumber(5)
  void clearPeriod() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get code => $_getSZ(5);
  @$pb.TagNumber(6)
  set code($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCode() => $_has(5);
  @$pb.TagNumber(6)
  void clearCode() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get recoveryCodes => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get error => $_getSZ(7);
  @$pb.TagNumber(8)
  set error($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(8)
  void clearError() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
