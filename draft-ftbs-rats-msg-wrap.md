---
v: 3

title: "RATS Conceptual Messages Wrapper"
abbrev: "RATS CMW"
docname: draft-ftbs-rats-msg-wrap-latest
category: std
consensus: true
submissionType: IETF

ipr: trust200902
area: "Security"
workgroup: "Remote ATtestation ProcedureS"
keyword: [ evidence, attestation result, endorsement, reference value ]

stand_alone: yes
smart_quotes: no
pi: [toc, sortrefs, symrefs]

author:
 - name: Henk Birkolz
   organization: Fraunhofer SIT
   email: henk.birkholz@sit.fraunhofer.de
 - name: Ned Smith
   organization: Intel
   email: ned.smith@intel.com
 - name: Thomas Fossati
   organization: arm
   email: thomas.fossati@arm.com
 - name: Hannes Tschofenig
   organization: arm
   email: hannes.tschofenig@arm.com

normative:
  RFC4648: base64
  RFC6838: media-types
  RFC7252: coap
  RFC8259: json
  RFC8610: cddl
  RFC9165: cddlplus
  RFC9277:
  STD94:
    -: cbor
    =: RFC8949

informative:
  I-D.ietf-rats-architecture: rats-arch
  I-D.ietf-rats-eat: rats-eat
  I-D.ietf-rats-ar4si: rats-ar4si
  I-D.fossati-tls-attestation: tls-a
  DICE-arch:
    author:
      org: "Trusted Computing Group"
    title: "DICE Attestation Architecture"
    target: https://trustedcomputinggroup.org/wp-content/uploads/DICE-Attestation-Architecture-r23-final.pdf
    date: March, 2021

--- abstract

This document defines two encapsulation formats for RATS conceptual
messages (i.e., evidence, attestation results, endorsements and
reference values.)

The first format uses a CBOR or JSON array with two members: one for the
type, another for the value.  The other format wraps the value in a CBOR
byte string and prepends a CBOR tag to convey the type information.

--- middle

# Introduction

The RATS architecture defines a handful of conceptual messages
(see {{Section 8 of -rats-arch}}), such as evidence and attestation results.
Each conceptual message can have multiple claims encoding and serialization
formats ({{Section 9 of -rats-arch}}). Such serialized message may
have to be transported via different protocols - for example, evidence
using an EAT {{-rats-eat}} encoding serialized as a CBOR payload in
a "background check" topological arrangement, or attestation results as
Attestation Results for Secure Interactions (AR4SI) {{-rats-ar4si}} payloads
in "passport" mode.

In order to minimize the cost associated with registration and maximize
interoperability, it is desirable to reuse their typing information
across such boundaries.

This document defines two encapsulation formats for RATS conceptual
messages that aim to achieve the goals stated above.

These encapsulation formats are designed to be:

* Self-describing - which removes the dependency on the framing provided
  by the embedding protocol (or the storage system) to convey exact
  typing information.

* Based on media types - which allows amortising their registration cost
  across many different usage scenarios.

A protocol designer could use these formats, for example, to convey
evidence, endorsements or reference values in certificates and CRLs
extensions ({{DICE-arch}}), to embed attestation results or evidence as
first class authentication credentials in TLS handshake messages
{{-tls-a}}, to transport attestation-related payloads in RESTful APIs,
or for stable storage of attestation results in form of file system
objects.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

In this document, CDDL {{-cddl}} {{-cddlplus}} is used to describe the
data formats.

The reader is assumed to be familiar with the vocabulary and concepts
defined in {{-rats-arch}}.

# Conceptual Message Wrapper Encodings

Two types of RATS Conceptual Message Wrapper (CMW) are specified in this
document:

1. a CMW using a CBOR or a JSON array ({{type-n-val}})

2. a CMW based on CBOR tags ({{cbor-tag}}).

## CMW Array {#type-n-val}

The CMW array illustrated in {{fig-cddl}} is composed of two members:

* type: either a text string representing a media-type (and optional
  parameters) {{-media-types}} or an unsigned integer corresponding to a
  CoAP Content-Format {{-coap}}

* value: the RATS conceptual message serialized according to the
  value defined in the type member.

A CMW array can be encoded as CBOR {{-cbor}} or JSON {{-json}}.

When using JSON, the value field is encoded as Base64 using the URL and
filename safe alphabet (Section 5 of {{-base64}}) without padding.

When using CBOR, the value field is encoded as a CBOR byte string.

~~~ cddl
{::include cddl/cmw.cddl}
~~~
{: #fig-cddl artwork-align="left"
   title="CDDL definition"}

## CMW CBOR Tags {#cbor-tag}

CBOR Tags used as CMW are derived from CoAP Content Format values.
If a CoAP Content Format exists for a RATS conceptual message, the
TN() transform defined in {{Appendix B of RFC9277}} can be used to
derive a corresponding CBOR tag in range \[1668546817, 1668612095\].

The RATS conceptual message is first serialized according to the Content
Format associated with the tag and then encoded as a CBOR byte string,
to which the tag is prepended.

### Use of Pre-existing CBOR Tags

If a CBOR tag has been registered in association with a certain RATS
conceptual message independently of a CoAP Content Format (i.e., it is
not obtained by applying the TN() transform), it can be readily used as
an encapsulation without the extra processing described in {{cbor-tag}}.

A consumer can always distinguish tags that have been derived via TN(),
which all fall in the \[1668546817, 1668612095\] range, from tags that
are not, and therefore apply the right decapsulation on receive.

## Decapsulation Algorithm

A parser decodes the octet string into a byte buffer
and then does a 1-byte lookahead, as illustrated in the
following pseudo code, to decide which format to use to
decode the remainder of the byte buffer:

~~~
switch b[0] {
case 0x82:
  return CBORArray
case 0x5b:
  return JSONArray
default:
  return CBORTag
}
~~~

# Examples

The (equivalent) examples below assume the media-type
`application/vnd.example.rats-conceptual-msg` has been registered
alongside a corresponding CoAP content format `30001`.  The CBOR tag
`1668576818` is derived applying the TN transform as described in
{{cbor-tag}}.

~~~ cbor-diag
{::include cddl/example-cbor-1.diag}
~~~
{: #fig-example-cbor artwork-align="left"
   title="CBOR encoding"}

~~~ cbor-diag
{::include cddl/example-json-1.diag}
~~~
{: #fig-example-json artwork-align="left"
   title="JSON encoding"}

~~~ cbor-diag
1668576818(h'abcdabcd')
~~~
{: #fig-example-cbor-tag artwork-align="left"
   title="CBOR tag"}

# Security Considerations

This document defines two encapsulation formats for RATS
conceptual messages. The messages themselves and their
encoding ensure security protection. For this reason
there are no further security requirements raised by
the introduction of this encapsulation.

Changing the encapsulation of a payload by an adversary
will result in incorrect processing of the encapsulated
messages and this will subsequently lead to a processing
error.


# IANA Considerations

When registering a new media type for evidence, in addition to its
syntactical description, the author SHOULD provide a public and stable
description of the signing and appraisal procedures associated with
the data format.

--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge.
