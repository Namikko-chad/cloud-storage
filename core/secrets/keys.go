package secrets

import (
	"crypto/ed25519"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math/big"
	"strings"

	"github.com/decred/dcrd/dcrec/secp256k1/v4"
	"golang.org/x/crypto/sha3"
	"golang.org/x/crypto/ssh"
)

// SSHKey is the public half of an SSH private key.
type SSHKey struct {
	Type          string // ssh-ed25519, ssh-rsa, ecdsa-sha2-nistp256, ...
	AuthorizedKey string // one authorized_keys line, with the comment
	Fingerprint   string // SHA256:...
}

// SSHPublic derives the public key from a private key in OpenSSH or PEM
// form. An encrypted key needs its passphrase, unless the file carries
// the public key in the clear (the OpenSSH format does).
func SSHPublic(private, passphrase, comment string) (SSHKey, error) {
	pemBytes := []byte(strings.TrimSpace(private) + "\n")
	if strings.TrimSpace(private) == "" {
		return SSHKey{}, invalid("the private key is empty")
	}
	var pub ssh.PublicKey
	raw, err := ssh.ParseRawPrivateKey(pemBytes)
	var missing *ssh.PassphraseMissingError
	switch {
	case errors.As(err, &missing) && passphrase != "":
		if raw, err = ssh.ParseRawPrivateKeyWithPassphrase(pemBytes, []byte(passphrase)); err != nil {
			return SSHKey{}, invalidf("wrong passphrase or damaged key: %w", err)
		}
	case errors.As(err, &missing) && missing.PublicKey != nil:
		pub = missing.PublicKey
	case errors.As(err, &missing):
		return SSHKey{}, invalid("the key is encrypted: enter its passphrase")
	case err != nil:
		return SSHKey{}, invalidf("not an SSH private key: %w", err)
	}
	if pub == nil {
		signer, err := ssh.NewSignerFromKey(raw)
		if err != nil {
			return SSHKey{}, invalidf("unsupported SSH key: %w", err)
		}
		pub = signer.PublicKey()
	}
	line := strings.TrimSpace(string(ssh.MarshalAuthorizedKey(pub)))
	if c := strings.TrimSpace(comment); c != "" {
		line += " " + strings.ReplaceAll(c, "\n", " ")
	}
	return SSHKey{Type: pub.Type(), AuthorizedKey: line, Fingerprint: ssh.FingerprintSHA256(pub)}, nil
}

// Network a web3 key belongs to.
type Network string

const (
	// NetworkEVM: Ethereum and every EVM chain (one address for all).
	NetworkEVM    Network = "evm"
	NetworkSolana Network = "solana"
)

// Web3Key is the public half of a web3 private key.
type Web3Key struct {
	Type      string // secp256k1, ed25519
	PublicKey string
	Address   string
}

// Web3Public derives the public key and the address from a private key.
//   - EVM: 32 bytes in hex (with or without 0x).
//   - Solana: base58 of the 64-byte keypair (wallet export), the JSON
//     array of a solana-keygen file, or the 32-byte seed in hex or base58.
func Web3Public(n Network, private string) (Web3Key, error) {
	s := strings.TrimSpace(private)
	if s == "" {
		return Web3Key{}, invalid("the private key is empty")
	}
	switch n {
	case NetworkEVM:
		return evmPublic(s)
	case NetworkSolana:
		return solanaPublic(s)
	}
	return Web3Key{}, invalidf("unknown network %q", n)
}

func evmPublic(s string) (Web3Key, error) {
	s = strings.TrimPrefix(strings.TrimPrefix(s, "0x"), "0X")
	b, err := hex.DecodeString(s)
	if err != nil || len(b) != 32 {
		return Web3Key{}, invalid("an EVM private key is 64 hex digits")
	}
	defer wipe(b)
	var k secp256k1.ModNScalar
	if overflow := k.SetByteSlice(b); overflow || k.IsZero() {
		return Web3Key{}, invalid("not a valid secp256k1 private key")
	}
	priv := secp256k1.NewPrivateKey(&k)
	defer priv.Zero()
	pub := priv.PubKey().SerializeUncompressed() // 0x04 || X || Y
	h := sha3.NewLegacyKeccak256()
	h.Write(pub[1:])
	return Web3Key{
		Type:      "secp256k1",
		PublicKey: "0x" + hex.EncodeToString(pub),
		Address:   checksumAddress(h.Sum(nil)[12:]),
	}, nil
}

// checksumAddress is the EIP-55 mixed-case form of an address.
func checksumAddress(addr []byte) string {
	lower := hex.EncodeToString(addr)
	h := sha3.NewLegacyKeccak256()
	h.Write([]byte(lower))
	sum := h.Sum(nil)
	out := []byte(lower)
	for i, c := range out {
		nibble := sum[i/2] >> 4
		if i%2 == 1 {
			nibble = sum[i/2] & 0x0f
		}
		if c >= 'a' && nibble >= 8 {
			out[i] = c - 32
		}
	}
	return "0x" + string(out)
}

func solanaPublic(s string) (Web3Key, error) {
	b, err := solanaBytes(s)
	if err != nil {
		return Web3Key{}, err
	}
	defer wipe(b)
	var priv ed25519.PrivateKey
	switch len(b) {
	case ed25519.SeedSize:
		priv = ed25519.NewKeyFromSeed(b)
	case ed25519.PrivateKeySize:
		priv = ed25519.NewKeyFromSeed(b[:32])
		if string(priv[32:]) != string(b[32:]) {
			return Web3Key{}, invalid("the keypair's public half does not match its secret")
		}
	default:
		return Web3Key{}, invalid("a Solana key is 32 or 64 bytes")
	}
	defer wipe(priv)
	addr := base58Encode(priv[32:])
	return Web3Key{Type: "ed25519", PublicKey: addr, Address: addr}, nil
}

func solanaBytes(s string) ([]byte, error) {
	if strings.HasPrefix(s, "[") {
		var nums []int
		if err := json.Unmarshal([]byte(s), &nums); err != nil {
			return nil, invalid("not a keypair file (JSON array of bytes)")
		}
		b := make([]byte, len(nums))
		for i, n := range nums {
			if n < 0 || n > 255 {
				return nil, invalid("not a keypair file (JSON array of bytes)")
			}
			b[i] = byte(n)
		}
		return b, nil
	}
	if b, err := hex.DecodeString(strings.TrimPrefix(s, "0x")); err == nil && len(b) == 32 {
		return b, nil
	}
	b, err := base58Decode(s)
	if err != nil {
		return nil, invalid("a Solana key is base58, hex or a JSON byte array")
	}
	return b, nil
}

const base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

func base58Encode(b []byte) string {
	n := new(big.Int).SetBytes(b)
	base, mod := big.NewInt(58), new(big.Int)
	var out []byte
	for n.Sign() > 0 {
		n.DivMod(n, base, mod)
		out = append(out, base58Alphabet[mod.Int64()])
	}
	for _, c := range b {
		if c != 0 {
			break
		}
		out = append(out, '1')
	}
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return string(out)
}

func base58Decode(s string) ([]byte, error) {
	n, base := new(big.Int), big.NewInt(58)
	zeros := 0
	for i, c := range s {
		d := strings.IndexRune(base58Alphabet, c)
		if d < 0 {
			return nil, errors.New("base58: bad character")
		}
		if d == 0 && i == zeros {
			zeros++
		}
		n.Mul(n, base).Add(n, big.NewInt(int64(d)))
	}
	return append(make([]byte, zeros), n.Bytes()...), nil
}
