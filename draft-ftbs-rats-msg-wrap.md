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
   organization: Linaro
   email: thomas.fossati@linaro.org
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
  IANA.cwt:
  IANA.jwt:
  BCP26:
    -: ianacons
    =: RFC8126

informative:
  RFC7942: impl-status
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

entity:
  SELF: "RFCthis"

--- abstract

This document defines two encapsulation formats for RATS conceptual
messages (i.e., evidence, attestation results, endorsements and
reference values.)

The first format uses a CBOR or JSON array with two mandatory members,
one for the type, another for the value, and a third optional member
complementing the type field that says which kind of conceptual
message(s) are carried in the value.
The other format wraps the value in a CBOR byte string and prepends a
CBOR tag to convey the type information.

This document also defines a corresponding CBOR tag, as well as JSON Web Tokens (JWT) and CBOR Web Tokens (CWT) claims.  These allow embedding the wrapped conceptual messages into CBOR-based protocols and web tokens, respectively.

--- middle

# Introduction

The RATS architecture defines a handful of conceptual messages
(see {{Section 8 of -rats-arch}}), such as evidence and attestation results.
Each conceptual message can have multiple claims encoding and serialization
formats ({{Section 9 of -rats-arch}}).
Throughout their lifetime, RATS conceptual messages are typically transported
over different protocols.
For example, EAT {{-rats-eat}} evidence in a "background check" topological
arrangement first flows from Attester to Relying Party, and then from Relying
Party to Verifier, over separate protocol legs.
Attestation Results for Secure Interactions (AR4SI) {{-rats-ar4si}} payloads in
"passport" mode would go first from Verifier to Attester and then, at a later
point in time and over a different channel, from Attester to Relying Party.

It is desirable to reuse any typing information associated with the messages
across such protocol boundaries in order to minimize the cost associated with
type registrations and maximize interoperability.

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

The CDDL generic `JC<>` is used where there is a variance between CBOR
and JSON. The first argument is the CDDL for JSON and the second is the
CDDL for CBOR.

~~~ cddl
{::include cddl/cmw-array.cddl}
~~~
{: #fig-cddl-array artwork-align="left"
   title="CDDL definition of the Array format"}

It is composed of three members:

{: vspace="0"}

`type`:
: Either a text string representing a Content-Type (e.g., an EAT media type
{{-rats-eat-mt}}) or an unsigned integer corresponding to a CoAP Content-Format
number ({{Section 12.3 of -coap}}).

`value`:
: The RATS conceptual message serialized according to the
value defined in the type member.

`ind`:
: An optional bitmap that indicates which conceptual message types are
carried in the `value` field.  Any combination (i.e., any value between
1 and 15, included) is allowed.  This is useful only if the `type` is
potentially ambiguous and there is no further context available to the
CMW consumer to decide.  For example, this might be the case if the base
media type is not profiled (e.g., `application/eat+cwt`), if the `value`
field contains multiple conceptual messages with different types (e.g.,
both reference values and endorsements within the same `application/signed-corim+cbor`), or if the same profile identifier is
shared by different conceptual messages.
Future specifications may add new values to the `ind` field; see {{iana-ind-ext}}.

A CMW array can be encoded as CBOR {{-cbor}} or JSON {{-json}}.

When using JSON, the value field is encoded as Base64 using the URL and
filename safe alphabet ({{Section 5 of -base64}}) without padding.

When using CBOR, the value field is encoded as a CBOR byte string.

## CMW CBOR Tags {#cbor-tag}

CBOR Tags used as CMW may be derived from CoAP Content-Format numbers.
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
func CMWTypeSniff(b []byte) (CMW, error) {
  if len(b) == 0 {
    return Unknown
  }

  if b[0] == 0x82 || b[0] == 0x83 {
    return CBORArray
  } else if b[0] >= 0xc0 && b[0] <= 0xdb {
    return CBORTag
  } else if b[0] == 0x5b {
    return JSONArray
  }

  return Unknown
}
~~~

# Examples

The (equivalent) examples in {{ex-ja}}, {{ex-ca}}, and {{ex-ct}} assume that
the Media-Type-Name `application/vnd.example.rats-conceptual-msg` has been
registered alongside a corresponding CoAP Content-Format number `30001`.  The
CBOR tag `1668576818` is derived applying the `TN()` transform as described in
{{cbor-tag}}.

The example in {{ex-ca-ind}} is a signed CoRIM payload with an explicit CM
indicator `0b0000_0011` (3), meaning that the wrapped message contains both
Reference Values and Endorsements.

## JSON Array {#ex-ja}

~~~ cbor-diag
{::include cddl/example-json-1.diag}
~~~

Note that a CoAP Content-Format number can also be used with the JSON array
form.  That may be the case when it is known that the receiver can handle CoAP
Content-Formats and it is crucial to save bytes.

## CBOR Array {#ex-ca}

~~~ cbor-diag
{::include cddl/example-cbor-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/example-cbor-1.pretty}
~~~

Note that a Media-Type-Name can also be used with the CBOR array form,
for example if it is known that the receiver cannot handle CoAP
Content-Formats, or (unlike the case in point) if a CoAP Content-Format
number has not been registrered.

~~~ cbor-diag
{::include cddl/example-cbor-2.diag}
~~~

## CBOR Tag {#ex-ct}

~~~ cbor-diag
1668576818(h'abcdabcd')
~~~

with the following wire representation:

~~~
{::include cddl/example-cbor-tag-1.pretty}
~~~

## CBOR Array with explicit CM indicator {#ex-ca-ind}

~~~ cbor-diag
{::include cddl/example-cbor-3.diag}
~~~

with the following wire representation:

~~~
83                                    # array(3)
   78 1d                              # text(29)
      6170706c69636174696f6e2f7369676e65642d636f72696d2b63626f72
                                      # "application/signed-corim+cbor"
   47                                 # bytes(7)
      d28443a10126a1                  # "҄C\xA1\u0001&\xA1"
   03                                 # unsigned(3)
~~~

# Implementation Status

This section records the status of known implementations of the protocol
defined by this specification at the time of posting of this Internet-Draft,
and is based on a proposal described in {{-impl-status}}.
The description of implementations in this section is intended to assist the
IETF in its decision processes in progressing drafts to RFCs.
Please note that the listing of any individual implementation here does not
imply endorsement by the IETF.
Furthermore, no effort has been spent to verify the information presented here
that was supplied by IETF contributors.
This is not intended as, and must not be construed to be, a catalog of
available implementations or their features.
Readers are advised to note that other implementations may exist.

According to {{-impl-status}}, "this will allow reviewers and working groups to
assign due consideration to documents that have the benefit of running code,
which may serve as evidence of valuable experimentation and feedback that have
made the implemented protocols more mature.
It is up to the individual working groups to use this information as they see
fit".

## Project Veraison

The organization responsible for this implementation is Project Veraison, a
Linux Foundation project hosted at the Confidential Computing Consortium.

The software, hosted at [](https://github.com/veraison/cmw), provides a Golang
package that allows encoding and decoding of CMW payloads.
The implementation covers all the features presented in this draft.
The maturity level is alpha.
The license is Apache 2.0.
The developers can be contacted on the Zulip channel:
[](https://veraison.zulipchat.com/#narrow/stream/383526-CMW/).

# Security Considerations

This document defines two encapsulation formats for RATS conceptual
messages. The messages themselves and their encoding ensure security
protection. For this reason there are no further security requirements
raised by the introduction of this encapsulation.

Changing the encapsulation of a payload by an adversary will result in
incorrect processing of the encapsulated messages and this will
subsequently lead to a processing error.

# IANA Considerations

[^rfced] replace "{{&SELF}}" with the RFC number assigned to this document.

## CWT `cmw` Claim Registration

IANA is requested to add a new `cmw` claim to the "CBOR Web Token (CWT) Claims" registry {{IANA.cwt}} as follows:

* Claim Name: cmw
* Claim Description: A RATS Conceptual Message Wrapper
* Claim Key: TBD
* Claim Value Type(s): CBOR Array, or CBOR Tag
* Change Controller: IETF
* Specification Document(s): {{type-n-val}} and {{cbor-tag}} of {{&SELF}}

The suggested value for the Claim Key is 299.

## JWT `cmw` Claim Registration

IANA is requested to add a new `cmw` claim to the "JSON Web Token Claims" sub-registry of the "JSON Web Token (JWT)" registry {{IANA.jwt}} as follows:

* Claim Name: cmw
* Claim Description: A RATS Conceptual Message Wrapper
* Claim Value Type(s): JSON Array
* Change Controller: IETF
* Specification Document(s): {{type-n-val}} of {{&SELF}}

## CBOR Tag Registration

IANA is requested to add the following tag to the "CBOR Tags" {{!IANA.cbor-tags}} registry.

| CBOR Tag | Data Item | Semantics | Reference |
|----------|-----------|-----------|-----------|
| TBD      | CBOR array, CBOR tag | RATS Conceptual Message Wrapper | {{type-n-val}} and {{cbor-tag}} of {{&SELF}} |

## RATS Conceptual Message Wrapper (CMW) Indicators Registry {#iana-ind-ext}

This specification defines a new "RATS Conceptual Message Wrapper (CMW) Indicators" registry, with the policy "Expert Review" ({{Section 4.5 of -ianacons}}).

The objective is to have Indicators values registered for all RATS Conceptual Messages ({{Section 8 of -rats-arch}}).

### Instructions for the Designated Expert {#de-instructions}

The expert is instructed to add the values incrementally.

Acceptable values are those corresponding to RATS Conceptual Messages defined by the RATS architecture {{-rats-arch}} and any of its updates.

### Structure of Entries

Each entry in the registry must include:

{:vspace}
Indicator value:
: A number corresponding to the bit position in the `cm-ind` bitmap.

Conceptual Message name:
: A text string describing the RATS conceptual message this indicator corresponds to.

Reference:
: A reference to a document, if available, or the registrant.

The initial registrations for the registry are detailed in {{tab-ind-regs}}.

| Indicator value | Conceptual Message name | Reference |
|-----------------|-------------------------|-----------|
| 0 | Reference Values | {{&SELF}} |
| 1 | Endorsements | {{&SELF}} |
| 2 | Evidence | {{&SELF}} |
| 3 | Attestation Results | {{&SELF}} |
{: #tab-ind-regs title="CMW Indicators Registry Initial Contents"}

--- back

# RFC9193 Content-Type ABNF {#rfc9193-abnf}

~~~ cddl
{::include cddl/rfc9193.cddl}
~~~

# Registering and Using CMWs

{{fig-howto-cmw}} describes the registration preconditions for using
CMWs in either array or CBOR tag forms.

~~~ aasvg
       .---------------.   .---------.
      | Reuse EAT/CoRIM | | Register  |
      | media type(s)   | | new media |
      | + profile       | | type      |
       `---+----+------'   `-+----+--'
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

The list of currently open issues for this documents can be found at
[](https://github.com/thomas-fossati/draft-ftbs-rats-msg-wrap/issues).

<cref>Note to RFC Editor: please remove before publication.</cref>

# Acknowledgments
{:numbered="false"}

The authors would like to thank Carl Wallace and Carsten Bormann for their
reviews and suggestions.

[^note]: Note:
[^issue]: Open issue:
[^rfced]: RFC Editor:
