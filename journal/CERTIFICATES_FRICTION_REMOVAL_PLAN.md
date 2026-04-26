# Certificates Friction Removal Plan

## Problem statement

The cert maintenance burden in this build:
- Servers rotate their leaf certs every ~3 months (github.com, crates.io, static.crates.io)
- When that happens, compare-certificate.sh fails, the build stops, and someone must re-run `get-certificate.sh`, inspect the new chain, and update the committed `*-chain.crt` file
- Additionally, when a server switches to a different CA family (as crates.io did in early 2026, moving from Amazon to GlobalSign), the root CA must be added to the cargo bundle manually

## Root cause

`CARGO_HTTP_CAINFO` **completely replaces** the system trust store for cargo's HTTPS connections. It is not additive. If a root CA is not in that file, cargo rejects the certificate chain even if the root is in the system bundle.

`SSL_CERT_FILE` / `SSL_CERT_DIR` are used by x.py (Python), not cargo. Setting them correctly is sufficient for the Python download step (bootstrap tools from static.rust-lang.org).

`trust-certificate.sh` installs our custom server certs into the system CA store and runs `update-ca-certificates`, so after that step `/usr/local/etc/ssl/certs/ca-certificates.crt` contains:
- All standard Mozilla-included root CAs from `ca-certificates.tcz` (~146 certs, including GlobalSign Root CA - R3)
- Plus our custom server certs (crates.io, static.crates.io, github.com live chains)

But the Dockerfile then sets `CARGO_HTTP_CAINFO` to the partial `cargo-certificates.crt` bundle (server certs + manually added GlobalSign root), not to the full updated system bundle.

## Proposed fix

After `trust-certificate.sh` runs `update-ca-certificates`, point `CARGO_HTTP_CAINFO` to the updated system bundle instead of the custom partial bundle:

```dockerfile
# Current Dockerfile line (partial bundle — only our fetched server certs + explicit root):
ENV CARGO_HTTP_CAINFO=$COMPILE_DIR/cargo-certificates.crt

# Proposed (full updated system bundle — all standard roots + our custom certs):
ENV CARGO_HTTP_CAINFO=/usr/local/etc/ssl/certs/ca-certificates.crt
```

This works because:
1. `update-ca-certificates` has already merged our custom server certs into the system bundle
2. The system bundle includes GlobalSign Root CA - R3 and all other standard Mozilla roots
3. Any future CA rotation to a standard Mozilla-trusted CA is handled automatically

## What gets simpler

- `certificates/globalsign-root-ca-r3.crt` — no longer needed (GlobalSign R3 is already in the TCL system bundle). Can be removed along with its COPY line and the `get-certificate.sh` append logic.
- Future CA switches (server moves from one well-known root to another) — no manual root cert added to bundle.
- github.com, crates.io, static.crates.io leaf cert rotations — `compare-certificate.sh` still catches them and requires a committed chain update, but that is now the only remaining maintenance step.

## What stays the same

The `compare-certificate.sh` step is **retained**. It provides an early explicit failure and a human review gate when certs rotate. Without it, a cert rotation would be silently trusted. Given that cargo reaches out to external servers during the build, this check is worth keeping.

The `get-certificate.sh` step is **retained** — it fetches live certs that compare-certificate.sh uses for comparison, and also populates the custom bundle (still used by trust-certificate.sh to add certs to the system store).

## What changes

| File | Change |
|------|--------|
| `Dockerfile` | `ENV CARGO_HTTP_CAINFO` → `/usr/local/etc/ssl/certs/ca-certificates.crt` |
| `Dockerfile` | Remove `COPY certificates/globalsign-root-ca-r3.crt` line |
| `Dockerfile` | Remove `cp globalsign-root-ca-r3.crt` from the `RUN mkdir -p …` line |
| `tools/get-certificate.sh` | Remove the `if [ -f .../globalsign-root-ca-r3.crt ]` append block |
| `certificates/globalsign-root-ca-r3.crt` | Delete file |

`trust-certificate.sh` already exports `CARGO_HTTP_CAINFO` internally but it is overridden by the Dockerfile `ENV` line in subsequent RUN steps. The script's internal export is a no-op for the `./x.py dist` step — only the Dockerfile `ENV` matters there.

## Verification plan

Before merging, verify with a Docker build (not just local) that:
1. `compare-certificate.sh` still succeeds (cert comparison works as before)
2. `./x.py dist` proceeds past the cargo index fetch without SSL errors
3. The build completes end-to-end

Also verify (in a running container):
```sh
grep -c "BEGIN CERTIFICATE" /usr/local/etc/ssl/certs/ca-certificates.crt
# Should be > 146 (base) after update-ca-certificates added our custom certs

# Confirm GlobalSign R3 is present:
openssl crl2pkcs7 -nocrl -certfile /usr/local/etc/ssl/certs/ca-certificates.crt \
  | openssl pkcs7 -print_certs -noout 2>/dev/null | grep "GlobalSign Root CA - R3"
```

## Risk and mitigations

**Risk:** The TCL `ca-certificates.tcz` package could be missing a needed root CA (either by omission or a future package update).
**Mitigation:** The `compare-certificate.sh` step verifies the live cert chains. If a server switches to a CA not in Mozilla's trust store (very unlikely for crates.io/github.com), the build still fails at the SSL handshake, which is detectable. We can always fall back to adding that root explicitly.

**Risk:** Pointing CARGO_HTTP_CAINFO to the system bundle means cargo trusts all ~146 Mozilla roots, not just the ones we explicitly reviewed.
**Mitigation:** This is the same trust stance as any standard Linux system. The compare step still validates the specific chains in use. The upside (no surprise failures when servers rotate to any standard CA) outweighs the marginal reduction in explicit control.

## Status

- [ ] Discuss with Nic
- [ ] Implement (one commit: Dockerfile + get-certificate.sh + delete globalsign-root-ca-r3.crt)
- [ ] Build verification
- [ ] Merge
