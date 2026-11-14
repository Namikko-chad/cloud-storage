# Security policy

CloudSync stores encrypted data and secrets (passwords, private keys, 2FA seeds), so
security reports are taken seriously.

## Supported versions

Only the latest release receives security fixes.

## Reporting a vulnerability

Please **do not open a public issue**. Report privately through
[GitHub security advisories](https://github.com/Namikko-chad/cloud-storage/security/advisories/new).

Include what you found, how to reproduce it and what an attacker could gain. You will
get an answer within a week; fixes are released as soon as they are ready, and you
will be credited unless you prefer otherwise.

## Scope

In scope, for example:

- anything readable reaching a storage (file names, sizes, content, record fields);
- weaknesses in key derivation, encryption or object naming;
- plaintext secrets written to disk, logs or caches;
- ways for one device or storage to corrupt or roll back data of others;
- the local gRPC endpoint being reachable without the token.

Known limitations are listed in [README.md](README.md#current-limitations) (for example,
decrypted secrets in process memory may be swapped out).
