# age test files

Both files were encrypted with the passphrase `ledgerly-test` at work factor 10. They contain no real data.

- `hello-scrypt-node.age` holds the text `hello ledgerly` and a line break.
- `two-chunks-node.age` holds 131,079 bytes, where byte `i` is `(i * 31 + 7) & 255`. That is two full 64 KiB chunks and a short last one.

They were made with an independent age v1 implementation written on Node's built-in crypto (OpenSSL's scrypt, HKDF, HMAC and ChaCha20-Poly1305). It is separate from Ledgerly's Dart code, so the tests check that the two agree with the format, not just with themselves.

The reference `age` tool wasn't available when these files were made. To check with it:

```bash
age -d hello-scrypt-node.age
```

Also run `age -d` on a file Ledgerly exported. Both should open with the passphrase above.
