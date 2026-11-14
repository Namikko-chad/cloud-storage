# Contributing to CloudSync

Thanks for your interest! Bug reports, ideas and pull requests are welcome.

## Before you start

- For anything bigger than a small fix, open an issue first so we can agree on the
  approach.
- Read the architecture overview in [README.md](README.md) and the invariants in
  [CLAUDE.md](CLAUDE.md). They describe properties the code relies on (deterministic
  index fold, storage identity by ID, quorum locks, nothing readable on a storage, …);
  changes that break them will not be merged.
- Security problems go through [SECURITY.md](SECURITY.md), not public issues.

## Development

```bash
make vet test      # Go core
make race          # Go core with the race detector
make app-test      # flutter analyze + flutter test
make proto         # after editing proto/cloudsync.proto
```

Engine tests simulate several devices sharing in-memory storages; real rclone code
paths are covered with the `local` backend. See README.md for build requirements.

## Rules

- **English only** in code, identifiers, comments, commit messages and logs. Other
  languages are allowed only in UI translations and in translated documentation
  (e.g. `README.ru.md`).
- App UI strings go through `tr('English', 'Русский')` (`app/lib/core/i18n.dart`); Android
  resources have their translations in `values-<lang>/`.
- The app follows `DESIGN_MANIFEST.md` and `DESIGN_MANIFEST_MOBILITY.md`: use the widgets
  from `app/lib/presentation/common/hm.dart` and `HmColors` / `HmText`.
- Run `gofmt` and `dart format`; keep `make vet` and `flutter analyze` clean.
- Add tests for behaviour changes, especially in `core/index`, `core/lock` and
  `core/engine`.
- Add a line to the `[Unreleased]` section of [CHANGELOG.md](CHANGELOG.md).

## License

By contributing you agree that your contributions are licensed under the
[GNU GPL v3.0](LICENSE).
