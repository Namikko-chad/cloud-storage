# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Before 1.0.0 the on-storage format and the gRPC API may change between minor versions.

## [Unreleased]

## [0.1.0] - 2026-11-13

First public release.

### Added

- **Core (Go).**
  - Password-protected vault (`vault.cs`, Argon2id) with the master key, k/m, storages
    and devices; a copy is kept in every storage and merged across devices.
  - Storages on top of rclone (Google Drive, Mega, S3, WebDAV, Dropbox, OneDrive,
    Yandex Disk, local folders and more), identified by ID: several accounts of one
    type are independent storages; failure domains guide shard placement.
  - Keyed FastCDC chunking with packing of small files, XChaCha20-Poly1305 encryption,
    HMAC object names and Reed-Solomon k+m erasure coding (one shard per storage).
  - Serverless index: per-device encrypted operation journals folded deterministically
    by Lamport clock; concurrent edits produce conflict copies. Journals are packed by
    their owner every 64 segments.
  - Quorum lease locks for files open for writing, with expiry and a 30 s hold after close.
  - Files on demand with a local cache, pins and "keep everything on device";
    sequential-read prefetch, reads from the fastest storages and hedged shard requests.
  - Maintenance: `repair` (scrub with checksums, rewrite missing shards, move data off
    disabled storages, re-encode after a k/m change, optional rebalance) and `gc` with
    a 7-day grace period.
  - Password safe: passwords, SSH keys, web3 keys (Ethereum/EVM, Solana) and TOTP 2FA
    records with recovery codes, in groups with a picture; metadata and secrets are
    sealed with separate keys. Public keys, fingerprints and addresses are derived by
    the core.
- **CLI `cs`:** `init`, `passwd`, `backend add|ls|enable|disable`, `status`, `ls`,
  `put`, `get`, `cat`, `mkdir`, `rm`, `mv`, `pin`, `unpin`, `pins`, `lock`, `sync`,
  `repair`, `redundancy`, `gc`.
- **Daemon `cloudsyncd`:** gRPC API for the app, vault mount (FUSE on Linux, WinFsp on
  Windows), background sync and an on-disk upload queue that survives restarts.
- **App (Flutter) for Linux, Windows and Android:** unlock and first setup, files,
  storages (add wizard with browser sign-in for Drive, OneDrive, Dropbox), maintenance,
  vault settings, password safe with 2FA codes, event log; English and Russian UI;
  desktop tray; fingerprint unlock on Android.
- **Android:** in-process core (gomobile AAR), foreground sync service and a
  DocumentsProvider that exposes the vault in the system file picker with streamed reads.

[Unreleased]: https://github.com/Namikko-chad/cloud-storage/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Namikko-chad/cloud-storage/releases/tag/v0.1.0
