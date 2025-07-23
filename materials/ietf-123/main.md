footer: IETF 123, Madrid - RATS WG
slidenumbers: true
autoscale: true

# Conceptual Message Wrappers

## [draft-ietf-rats-msg-wrap](https://datatracker.ietf.org/doc/draft-ietf-rats-msg-wrap)

### IETF 123, Madrid - RATS WG

---

# Updates since IETF 122

Changes since -12 [(diff)](https://author-tools.ietf.org/iddiff?url1=draft-ietf-rats-msg-wrap-12&url2=draft-ietf-rats-msg-wrap-16&difftype=--html)

* Abstract rewrite (Hannes)
* New Section 3.1.1 "CM Type" (Carl)
* Explain use of `__cmwc_t` (Laurence)
* Add commentis to `CMWTypeDemux()` (Carl)

---

# Updates since IETF 122 (cont.)

* Clarify "protected" in Section 4 (Usama)

```
OLD
   This section highlights a number of mechanisms to add cryptographic
   protection to CMWs.

NEW (-16)
   This section highlights a number of mechanisms to add authentication,
   integrity and, if used with a challenge-response protocol, anti-
   replay protection to CMWs.

NEWER (PR#232)
   This section highlights a number of mechanisms through which protocol
   designers can add authentication, integrity and, if used with a
   challenge-response protocol, anti-replay protection when employing
   CMWs.  These properties must be evaluated carefully in the context of
   the relevant security model.
```

---

# Updates since IETF 122 (cont.)

* Fix `cty` claim in `signed-cbor-cmw-protected-hdr` (Carl)
* Use allocated codepoint for `id-pe-cmw` (35) (Russ)
* Add Section 8 "Privacy Considerations" (Mike O)
* Reflow "Security Considerations" (Usama)

---

# Running code updates

New Rust crate contributed by Ionuț:

* [https://github.com/veraison/rust-cmw](https://github.com/veraison/rust-cmw)

Updated Go implementation to match latest version:

* [https://github.com/veraison/cmw](https://github.com/veraison/cmw)

Experimental use of CMWs in Keylime to wrap TPM evidence.

---

# Next Steps

* Ready to ship

---

# Questions?

