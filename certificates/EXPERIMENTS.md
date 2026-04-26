# Certificate Experiments

## Experiment 1 - Why does cargo fail with TCL's system certificates?

**Hypothesis:** Cargo can't use the system certificates installed by `ca-certificates.tcz` in the TCL Docker image because something in the environment prevents cargo's HTTP client (reqwest) from finding or trusting them, even when `SSL_CERT_FILE` is set.

**Background observed:**
- `ca-certificates.tcz` IS installed successfully during the build: "Updating certificates in /usr/local/etc/ssl/certs... 146 added, 0 removed; done."
- The `./x.py dist` invocation explicitly sets `SSL_CERT_FILE=/usr/local/etc/ssl/certs/ca-certificates.crt SSL_CERT_DIR=/usr/local/etc/ssl/certs`
- Despite this, cargo fails TLS verification without `CARGO_HTTP_CAINFO` pointing to a custom bundle
- The workaround (custom bundle from `get-certificate.sh`) works

**Commands:** (to be run inside a running container from a completed build or interactively)
```sh
# Check what root CAs are in the TCL system bundle
grep "BEGIN CERTIFICATE" /usr/local/etc/ssl/certs/ca-certificates.crt | wc -l
# Check if Amazon Root CA 1 is present
openssl x509 -in /usr/local/etc/ssl/certs/ca-certificates.crt -noout -subject 2>/dev/null | grep Amazon
# Try fetching crates.io with system certs
curl --cacert /usr/local/etc/ssl/certs/ca-certificates.crt https://crates.io -v 2>&1 | head -30
# Try with CARGO_HTTP_CAINFO unset
unset CARGO_HTTP_CAINFO && cargo fetch 2>&1 | head -20
```

**Results:** Not yet run — need a running container to test.

**Findings:** Pending.

---

## Experiment 2 - What broke in the tcl-core-x86:17.x image?

**Hypothesis:** The floating `17.x-x86` tag was updated between the 1.93.1 build (last known good Docker build) and now, introducing regressions.

**Commands:**
```sh
docker run --rm linichotmailca/tcl-core-x86:17.x-x86 id
docker run --rm linichotmailca/tcl-core-x86:17.x-x86 ls -la /tmp
docker run --rm linichotmailca/tcl-core-x86:17.x-x86 ls -la /usr/bin/sudo
docker run --rm linichotmailca/tcl-core-x86:17.x-x86 ls -la /home/
```

**Results:** (run 2026-04-26)
```
uid=1001(tc) gid=50(staff) groups=50(staff)

drwxr-xr-t 1 root root 4096 — /tmp  (no world-write, sticky bit only)
---x--x--x 1 root root 124604 — /usr/bin/sudo  (no SUID bit!)
drwxr-x--- 4 root root 4096 — /home/tc  (owned by root, tc has no access)
```

**Findings:**
Three regressions in the updated `17.x-x86` image compared to what the 1.93.1 build needed:

1. `/tmp` has mode `1755` (no world-write) — `tce-load` can't create `/tmp/appserr` temp file
2. `/usr/bin/sudo` has no SUID bit — `tce-load`'s install step (uses sudo mount) silently fails
3. `/home/tc` is owned by `root:root` with mode `750` — `tc` user has no access to its own home directory

**Fix applied in Dockerfile** (commit `bf88a4e`):
```dockerfile
USER root
RUN chmod 1777 /tmp && chown -R tc:staff /tmp/tce /tmp/tcloop && chmod u+s /usr/bin/sudo \
    && chown tc:staff /home/tc
USER tc
```

**Recommended fix upstream:** The `tcl-core-x86` image build (separate repo) should be corrected so these permissions are right from the start. The rust-i586 Dockerfile workaround is a band-aid.

---

## Experiment 3 - Why does the github.com cert mismatch happen?

**Hypothesis:** github.com's TLS leaf certificate rotates periodically (every ~3 months). The committed `github-com-chain.crt` was last updated for a cert valid Jan 6 – Apr 5, 2026. By Apr 26, 2026 that cert expired and github.com is now serving a new leaf valid Mar 6 – Jun 3, 2026.

**Commands:**
```sh
openssl x509 -in certificates/github-com-chain.crt -noout -dates
echo "Q" | openssl s_client -showcerts -timeout -servername github.com github.com:443 2>&1 \
  | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
  | openssl x509 -noout -dates
```

**Results:** (run 2026-04-26)
```
# Old committed cert:
notBefore=Jan  6 00:00:00 2026 GMT
notAfter =Apr  5 23:59:59 2026 GMT   ← expired 21 days ago

# Live cert (host):
notBefore=Mar  6 00:00:00 2026 GMT
notAfter =Jun  3 23:59:59 2026 GMT   ← valid

# Live cert (inside Docker build):  same as host ✓
```

**Findings:**
- The intermediate CA (Sectigo Public Server Authentication CA DV E36) and root CA (Sectigo / USERTrust ECC) are unchanged.
- Only the leaf cert rotated. This is normal expected behaviour for github.com (~3-month cycle).
- Fix: re-run `get-certificate.sh` for github.com, copy result to `github-com-chain.crt`.
- This needs to be done every ~3 months, or automated.

---

## Experiment 4 - When does crates.io need cert updates?

**Hypothesis:** crates.io uses Amazon Trust Services CA. The cert chain changes when Amazon rotates the leaf or intermediate. From README: the Amazon RSA 2048 M04 intermediate was in use as of 2025-11-01, and that cert was valid until Nov 2026. So crates.io is likely stable for now.

**Commands:**
```sh
openssl x509 -in certificates/crates-io-chain.crt -noout -subject -dates -issuer
```

**Results:** (from 2026-04-26)
- Build r2: crates.io MATCHED (old Amazon cert still served as of build r2)
- Build r4: crates.io did NOT match — cert rotated between r2 and r4

Chain before rotation (committed Mar 5, 2026):
```
Leaf: CN=crates.io, issuer=Amazon RSA 2048 M04, valid Jan 16 2026 – Feb 14 2027
```

Chain after rotation (current as of Apr 26, 2026):
```
Leaf: CN=crates.io, issuer=GlobalSign Atlas R3 DV TLS CA 2025 Q4, valid Jan 15 2026 – Feb 16 2027
```

**Findings:**
- crates.io switched from Amazon RSA 2048 M04 to **GlobalSign Atlas R3 DV TLS CA 2025 Q4**, same as index.crates.io.
- Both crates.io and index.crates.io now use the same CA family. GlobalSign Root CA - R3 covers both.
- The rotation from Amazon to GlobalSign happened sometime between Mar 5 and Apr 26, 2026 — possibly coordinated with the index.crates.io change.
- The old `crates-io-chain.crt` had 3 certs (Amazon leaf + M04 intermediate + Amazon Root CA 1). New chain has 2 certs (leaf + Q4 intermediate); the GlobalSign root is now handled by `globalsign-root-ca-r3.crt`.

---

---

## Experiment 5 - Is GlobalSign Root CA R3 in the TCL ca-certificates bundle?

**Hypothesis:** `ca-certificates.tcz` DOES include GlobalSign Root CA - R3 (it's in Mozilla's trust store and most distros ship it). If so, after `trust-certificate.sh` runs `update-ca-certificates`, the system bundle `/usr/local/etc/ssl/certs/ca-certificates.crt` has it — but CARGO_HTTP_CAINFO overrides the system store entirely, which is why cargo can't use it.

**Commands:** (run inside TCL container with ca-certificates installed)
```sh
# After tce-load installs ca-certificates.tcz:
grep -c "BEGIN CERTIFICATE" /usr/local/etc/ssl/certs/ca-certificates.crt
# Check if GlobalSign Root CA R3 is present in system bundle:
openssl crl2pkcs7 -nocrl -certfile /usr/local/etc/ssl/certs/ca-certificates.crt \
  | openssl pkcs7 -print_certs -noout 2>/dev/null | grep "GlobalSign Root CA - R3"
```

**Results:** Not yet verified directly; indirect evidence from build logs: tce-load installs ca-certificates.tcz successfully (146 certs added). The R3 root is a standard Mozilla-included cert so very likely present.

**Findings:** Pending direct confirmation. The root cause of cargo not using system certs is clearly that CARGO_HTTP_CAINFO is set to a custom bundle — that replaces the system store. As long as CARGO_HTTP_CAINFO is set, cargo ignores system certs. This is the designed behaviour.

**Implication for friction reduction:** Rather than maintaining a custom bundle of individual server certs, we could set `CARGO_HTTP_CAINFO` to the system bundle (`/usr/local/etc/ssl/certs/ca-certificates.crt`) after `update-ca-certificates` has run. That would let cargo trust any standard cert without manual maintenance. See CERTIFICATES_FRICTION_REMOVAL_PLAN.md for this proposal.

---

## Open questions (for Experiment 1)

1. Does `ca-certificates.tcz` include Amazon Root CA 1? If not, that's the direct cause: cargo can't trust the cert chain because the root is missing from the system bundle.
2. Does the cargo version in the TCL build use `SSL_CERT_FILE` from the environment, or does it look for it somewhere else?
3. Is `CARGO_HTTP_CAINFO` a complete replacement for the system trust store (i.e., only certs in that file are trusted), or is it additive? If replacement: setting it to a bundle that includes only the servers we contact (not all root CAs) is correct and intentional.
