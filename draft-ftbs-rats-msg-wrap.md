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
   email: hannes.tschofenig@gmx.net

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
  RFC9193: senml-cf
  RFC9334: rats-arch
  I-D.ietf-rats-eat: rats-eat
  I-D.ietf-rats-eat-media-type: rats-eat-mt
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
formats ({{Section 9 of -rats-arch}}). Such serialized messages may
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

* Based on media types {{-media-types}} - which allows amortising their
  registration cost across many different usage scenarios.

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

This document reuses the terms defined in {{Section 2 of -senml-cf}}
(e.g., "Content-Type").

# Conceptual Message Wrapper Encodings

Two types of RATS Conceptual Message Wrapper (CMW) are specified in this
document:

1. A CMW using a CBOR or JSON array ({{type-n-val}});
1. A CMW based on CBOR tags ({{cbor-tag}}).

## CMW Array {#type-n-val}

The CMW array format is defined in {{fig-cddl-array}}.  (To improve clarity,
the `Content-Type` ABNF is defined separately in {{rfc9193-abnf}}.)

~~~ cddl
{::include cddl/cmw-array.cddl}
~~~
{: #fig-cddl-array artwork-align="left"
   title="CDDL definition of the Array format"}

It is composed of two members:

{: vspace="0"}

`type`:
: Either a text string representing a Content-Type (e.g., an EAT media type
{{-rats-eat-mt}}) or an unsigned integer corresponding to a CoAP Content-Format
number ({{Section 12.3 of -coap}}).

`value`:
: The RATS conceptual message serialized according to the
value defined in the type member.

A CMW array can be encoded as CBOR {{-cbor}} or JSON {{-json}}.

When using JSON, the value field is encoded as Base64 using the URL and
filename safe alphabet (Section 5 of {{-base64}}) without padding.

When using CBOR, the value field is encoded as a CBOR byte string.

## CMW CBOR Tags {#cbor-tag}

CBOR Tags used as CMW are derived from CoAP Content-Format numbers.
If a CoAP content format exists for a RATS conceptual message, the
`TN()` transform defined in {{Appendix B of RFC9277}} can be used to
derive a corresponding CBOR tag in range \[1668546817, 1668612095\].

The RATS conceptual message is first serialized according to the
Content-Format number associated with the CBOR tag and then encoded as a
CBOR byte string, to which the tag is prepended.

The CMW CBOR Tag is defined in {{fig-cddl-cbor-tag}}.

~~~ cddl
{::include cddl/cmw-cbor-tag.cddl}
~~~
{: #fig-cddl-cbor-tag artwork-align="left"
   title="CDDL definition of the CBOR Tag format"}

### Use of Pre-existing CBOR Tags

If a CBOR tag has been registered in association with a certain RATS
conceptual message independently of a CoAP content format (i.e., it is
not obtained by applying the `TN()` transform), it can be readily used
as an encapsulation without the extra processing described in
{{cbor-tag}}.

A consumer can always distinguish tags that have been derived via
`TN()`, which all fall in the \[1668546817, 1668612095\] range, from
tags that are not, and therefore apply the right decapsulation on
receive.

## Decapsulation Algorithm

After removing any external framing (for example, the ASN.1 OCTET STRING
if the CMW is carried in a certificate extension {{DICE-arch}}), the CMW
decoder does a 1-byte lookahead, as illustrated in the following pseudo
code, to decide how to decode the remainder of the byte buffer:

~~~
func CMWDecode(b []byte) (CMW, error) {
    if len(b) < CMWMinSize {
        return CMW{}, errors.New("CMW too short")
    }

    switch b[0] {
    case 0x82:
        return cborArrayDecode(b)
    case 0x5b:
        return jsonArrayDecode(b)
    default:
        return cborTagDecode(b)
    }
}
~~~

# Examples

The (equivalent) examples below assume the Media-Type-Name
`application/vnd.example.rats-conceptual-msg` has been registered
alongside a corresponding CoAP Content-Format number `30001`.  The CBOR
tag `1668576818` is derived applying the `TN()` transform as described
in {{cbor-tag}}.

## JSON Array

~~~ cbor-diag
{::include cddl/example-json-1.diag}
~~~

## CBOR Array

~~~ cbor-diag
{::include cddl/example-cbor-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/example-cbor-1.pretty}
~~~

## CBOR Tag {#cbor-tag-example}

~~~ cbor-diag
1668576818(h'abcdabcd')
~~~

with the following wire representation:

~~~
{::include cddl/example-cbor-tag-1.pretty}
~~~

# Registering a Media Type for Evidence

[^note] Not sure whether this advice should go.

When registering a new media type for evidence, in addition to its
syntactical description, the author SHOULD provide a public and stable
description of the signing and appraisal procedures associated with
the data format.

# Security Considerations

This document defines two encapsulation formats for RATS conceptual
messages. The messages themselves and their encoding ensure security
protection. For this reason there are no further security requirements
raised by the introduction of this encapsulation.

Changing the encapsulation of a payload by an adversary will result in
incorrect processing of the encapsulated messages and this will
subsequently lead to a processing error.

# IANA Considerations

This document does not make any requests to IANA.

--- back

# RFC9193 Content-Type ABNF {#rfc9193-abnf}

~~~ cddl
{::include cddl/rfc9193.cddl}
~~~

# Registering and Using CMWs

{{fig-howto-cmw}} describes the registration preconditions for using
CMWs in either array or CBOR tag forms.

~~~ aasvg
        .-------------.    .---------.
       | Reuse EAT     |  | Register  |
       | media type    |  | new media |
       | + eat_profile |  | type      |
        `--+----+-----'    `-+----+--'
           |    |            |    |
           |  .-+------------+-.  |
           | |  |  Register  |  | |
         .-(-+-'   new CoAP   `-+-(-.
        |  | |  Content-Format  | |  |
        |  |  `-------+--------'  |  |
        |  |          |           |  |
        |  |          v           |  |
        |  |   .--------------.   |  |  .--------.
        |  |  | Automatically  |  |  | | Existing |
        |  |  | derive CBOR    |  |  | | CBOR     |
        |  |  | tag [RFC9277]  |  |  | | tag      |
        |  |   `------+-------'   |  |  `---+----'
        |  |          |           |  |      |
        |  |          |.----------(--(-----'
        |  |          |           |  |
        |  |          v           |  |
        |  |   .----------------. |  |
        |  |  /  CBOR tag CMW  /  |  |
        v  v `----------------'   v  v
    .--------------------------------------.
   /             Array CMW                /
  `--------------------------------------'
~~~
{: #fig-howto-cmw artwork-align="left"
   title="How To CMW"}

# Open Issues

<cref>Note to RFC Editor: please remove before publication.</cref>

The list of currently open issues for this documents can be found at
[](https://github.com/thomas-fossati/draft-ftbs-rats-msg-wrap/issues).

# Acknowledgments
{:numbered="false"}

The authors would like to thank Carl Wallace and Carsten Bormann for their
reviews and suggestions.

[^note]: Note:
