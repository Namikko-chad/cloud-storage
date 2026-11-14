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

import 'package:protobuf/protobuf.dart' as $pb;

class SecretKind extends $pb.ProtobufEnum {
  static const SecretKind SECRET_KIND_UNSPECIFIED =
      SecretKind._(0, _omitEnumNames ? '' : 'SECRET_KIND_UNSPECIFIED');
  static const SecretKind SECRET_PASSWORD =
      SecretKind._(1, _omitEnumNames ? '' : 'SECRET_PASSWORD');
  static const SecretKind SECRET_SSH =
      SecretKind._(2, _omitEnumNames ? '' : 'SECRET_SSH');
  static const SecretKind SECRET_WEB3 =
      SecretKind._(3, _omitEnumNames ? '' : 'SECRET_WEB3');
  static const SecretKind SECRET_TOTP =
      SecretKind._(4, _omitEnumNames ? '' : 'SECRET_TOTP');

  static const $core.List<SecretKind> values = <SecretKind>[
    SECRET_KIND_UNSPECIFIED,
    SECRET_PASSWORD,
    SECRET_SSH,
    SECRET_WEB3,
    SECRET_TOTP,
  ];

  static final $core.List<SecretKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SecretKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SecretKind._(super.value, super.name);
}

class Web3Network extends $pb.ProtobufEnum {
  static const Web3Network WEB3_NETWORK_UNSPECIFIED =
      Web3Network._(0, _omitEnumNames ? '' : 'WEB3_NETWORK_UNSPECIFIED');
  static const Web3Network WEB3_EVM =
      Web3Network._(1, _omitEnumNames ? '' : 'WEB3_EVM');
  static const Web3Network WEB3_SOLANA =
      Web3Network._(2, _omitEnumNames ? '' : 'WEB3_SOLANA');

  static const $core.List<Web3Network> values = <Web3Network>[
    WEB3_NETWORK_UNSPECIFIED,
    WEB3_EVM,
    WEB3_SOLANA,
  ];

  static final $core.List<Web3Network?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Web3Network? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Web3Network._(super.value, super.name);
}

class Event_Kind extends $pb.ProtobufEnum {
  static const Event_Kind KIND_UNSPECIFIED =
      Event_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const Event_Kind TREE_CHANGED =
      Event_Kind._(1, _omitEnumNames ? '' : 'TREE_CHANGED');
  static const Event_Kind STATE_CHANGED =
      Event_Kind._(2, _omitEnumNames ? '' : 'STATE_CHANGED');
  static const Event_Kind SYNC_DONE =
      Event_Kind._(3, _omitEnumNames ? '' : 'SYNC_DONE');
  static const Event_Kind SYNC_ERROR =
      Event_Kind._(4, _omitEnumNames ? '' : 'SYNC_ERROR');
  static const Event_Kind SECRETS_CHANGED =
      Event_Kind._(5, _omitEnumNames ? '' : 'SECRETS_CHANGED');

  static const $core.List<Event_Kind> values = <Event_Kind>[
    KIND_UNSPECIFIED,
    TREE_CHANGED,
    STATE_CHANGED,
    SYNC_DONE,
    SYNC_ERROR,
    SECRETS_CHANGED,
  ];

  static final $core.List<Event_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static Event_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Event_Kind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
