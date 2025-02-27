footer: IETF 122, Bangkok - RATS WG
slidenumbers: true
autoscale: true
theme: Plain Thomas

# Conceptual Message Wrappers

## [draft-ietf-rats-msg-wrap](https://datatracker.ietf.org/doc/draft-ietf-rats-msg-wrap)

### IETF 122, Bangkok - RATS WG

---

# Quick Recap

* Wrapper format for transporting *any* attestation message in *any* "hosting" protocol
* JSON and CBOR serialisations
* Typing based on Media Types [[RFC6838]](https://rfc-editor.org/rfc/rfc6838)

For more details see:

* [Presentation @ CCC Attestation SIG](https://github.com/CCC-Attestation/meetings/blob/main/materials/ThomasFossati_CMW.pdf)

---

# Update since Dublin

A lot of work...

[.column]

33 PRs merged

^```shell
^gh pr list -R ietf-rats-wg/draft-ietf-rats-msg-wrap --search "closed:>=2024-11-07" --state closed --limit 100
^```

[.column]

22 Issues closed

^```shell
^gh pr list -R ietf-rats-wg/draft-ietf-rats-msg-wrap --search "closed:>=2024-11-07" --state closed --limit 100
^```

---

# (Most Interesting) PRs

| ID | TYPE | TITLE |
|----|------|-------|
| #134 | FEAT | CBOR tag numbers must be TN-derived |
| #165 | FEAT | Drop tunnels |
| #164 | FEAT | Add COSE- and JOSE-based signatures |
| #181 | EDIT | "Adam's Sweep" |
| #161 | FIX | Add missing escape in `.abnf`'d quoted-pair |
| #184 | FIX | Add indefinite-length case to record demux |
| (...27 more...) |

---

# Open Issues

| ID | TITLE | Notes |
|----|-------|-------|
| #169 | Is the `cmw` claim too coarse-grained to be useful? | EAT & CMW synergy |
| #154 | Proposal to replace id-pe-cmw with ASN.1-based CMW Record | ASN.1 CMW |
| #156 | Consider supporting COSE/JOSE security | Done? |
| #153 | How to use cmw for alternative CMs | Clarification needed from Ned |

---

# #169

* CBOR and JSON CMWs can be tunneled in CWT/JWT using the `"cmw"` claim
* However, `"cmw"` could be too coarse-grained when used in EAT

[.column]

### Options

1. Add EAT-specific CMW claims (e.g., `"nested-token"`)
1. WONTFIX, i.e.: do it in a separate "CMW in EAT" I-D

[.column]

### Recommendation

WONTFIX

---

# #154

* CBOR and JSON CMWs can be tunneled in X.509 using the `id-pe-cmw` extension
* However, $$\nexists$$ "native" ASN.1 CMW

[.column]

### Options

* Add an ASN.1 CMW based on the [wiki proposal](https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/wiki/CMW-in-ASN.1)
* WONTFIX, i.e.: do it, if there is enough pull, in a separate "ASN.1 CMW" I-D

[.column]

### Recommendation

WONTFIX

---

# Next Steps

Decide on the open issues

2nd WGLC

---

# FIN
