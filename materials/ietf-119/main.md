footer: IETF 119, Brisbane - RATS WG
slidenumbers: true
autoscale: true

# Conceptual Message Wrappers

## [draft-ietf-rats-msg-wrap](https://datatracker.ietf.org/doc/draft-ietf-rats-msg-wrap)

### IETF 119, Brisbane - RATS WG

---

# Status Update

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

---

# Next Steps

-05 with some further CDDL-related improvements

2nd WGLC?

---
