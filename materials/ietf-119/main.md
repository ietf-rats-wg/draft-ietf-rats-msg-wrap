footer: IETF 119, Brisbane - RATS WG
slidenumbers: true
autoscale: true

# Conceptual Message Wrappers

## [draft-ietf-rats-msg-wrap](https://datatracker.ietf.org/doc/draft-ietf-rats-msg-wrap)

### IETF 119, Brisbane - RATS WG

---

# Quick Recap

* Wrapper format for transporting *any* attestation message in *any* "hosting" protocol
* JSON and CBOR serialisations
* Typing based on Media Types [[RFC6838]](https://rfc-editor.org/rfc/rfc6838)

For more details see:

* [Presentation @ CCC Attestation SIG](https://github.com/CCC-Attestation/meetings/blob/main/materials/ThomasFossati_CMW.pdf)

---

# Updates

* (1st) WGLC concluded
* Relation with other drafts
* Next steps

---

# WGLC Summary

Excellent feedback, thank you all!

Major improvements both editorial and content-wise

---

# Collections

* Unifying CMW and CMW collections:
  * CMW collections have been added to the top-level CMW production

* Mixed encodings in collections:
  * A "tunnelling" construct now exists to move CMWs of one type into collections of another type

---

# Collection (cont.)

* The PKIX extension now applies to both type&value CMWs and collections
  * Clarify relation with TCG's OID semantics

* An optional `"__cmcw_t"` (reserved) label was added to type a collection with a unique identifier
  * It can be used as a parameter for the `"application/cmw"` media types

---

# Editorial

CDDL refactoring to improve readability

`s/array/record/g`

Added more examples

---

# Relations with other drafts

[draft-ietf-lamps-csr-attestation](https://datatracker.ietf.org/doc/draft-ietf-lamps-csr-attestation/)

[draft-bft-rats-kat](https://datatracker.ietf.org/doc/draft-bft-rats-kat/)

[draft-fossati-tls-attestation](https://datatracker.ietf.org/doc/draft-fossati-tls-attestation/)

---

# Next Steps

[.column]

* Get a document shepherd (Ionuț Mihalcea volunteered)

* -05 with some further CDDL-related and editorial improvements
  * [#81 "Trust contexts to consider"](https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/issues/81) 
  * [#74 "Add prose for example meanings of labels in cmw-collection"](https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/issues/74)

* 2nd WGLC?

[.column]

```
                     cmw-05            |--| = 1w
                       |
                       v
                 |--|--|--|--|--|--|-> t
                 ^      ^      ^
                 |      '______'
                now     2nd WGLC
```

---

# FIN