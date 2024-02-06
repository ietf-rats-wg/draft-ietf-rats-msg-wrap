---
v: 3

title: "RATS Conceptual Messages Wrapper (CMW)"
abbrev: "RATS CMW"
docname: draft-ietf-rats-msg-wrap-latest
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
 - name: Henk Birkholz
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
  RFC5280: pkix
  RFC5912:
  RFC6268:
  RFC6838: media-types
  RFC7252: coap
  STD90:
    -: json
    =: RFC8259
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
  X.680: CCITT.X680.1994

informative:
  RFC7942: impl-status
  RFC9193: senml-cf
  RFC9334: rats-arch
  I-D.ietf-rats-eat: rats-eat
  I-D.ietf-rats-eat-media-type: rats-eat-mt
  I-D.ietf-rats-ar4si: rats-ar4si
  I-D.fossati-tls-attestation: tls-a
  I-D.ietf-lamps-csr-attestation: csr-a
  DICE-arch:
    author:
      org: "Trusted Computing Group"
    title: "DICE Attestation Architecture"
    target: https://trustedcomputinggroup.org/wp-content/uploads/DICE-Attestation-Architecture-Version-1.1-Revision-18_pub.pdf
    date: January, 2024

entity:
  SELF: "RFCthis"

--- abstract

This document defines two encapsulation formats for RATS conceptual
messages (i.e., Evidence, Attestation Results, Endorsements and
Reference Values.)

The first encapsulation format uses a CBOR or JSON array with two mandatory members,
one for the type, another for the value, and a third optional member
complementing the type field that says which kind of conceptual
message(s) are carried in the value.
The other format wraps the value in a CBOR byte string and prepends a
CBOR tag to convey the type information.

This document also defines a corresponding CBOR tag, as well as JSON Web Tokens (JWT) and CBOR Web Tokens (CWT) claims.  These allow embedding the wrapped conceptual messages into CBOR-based protocols and web APIs, respectively.

--- middle

# Introduction

The RATS architecture defines a handful of conceptual messages
(see {{Section 8 of -rats-arch}}), such as Evidence and Attestation Results.
Each conceptual message can have multiple claims encoding and serialization
formats ({{Section 9 of -rats-arch}}). Throughout their lifetime, RATS
conceptual messages are typically transported over different protocols.
For example,

- EAT {{-rats-eat}} Evidence in a "background check" topological
arrangement first flows from Attester to Relying Party, and then from Relying
Party to Verifier, over separate protocol legs.

- Attestation Results for Secure Interactions (AR4SI) {{-rats-ar4si}} payloads in
"passport" mode would be sent by the Verifier to the Attester and then, at a later
point in time and over a different channel, from the Attester to the Relying Party.

It is desirable to reuse any typing information associated with the messages
across such protocol boundaries to minimize the cost associated with
type registrations and maximize interoperability. With the CMW format described
in this document, protocol designers do not need to update protocol specifications
to support different conceptual messages. This approach reduces the implementation
effort for developers to support different attestation technologies. For example,
an implementer of a Relying Party application does not need to parse
attestation-related conceptual messages, such as different Evidence formats,
but can instead utilize the CMW format to be agnostic to the attestation
technology.

This document defines two encapsulation formats for RATS conceptual
messages that aim to achieve the goals stated above.

These encapsulation formats have been specifically designed to possess the following characteristics:

* They are self-describing, which means that they can convey precise typing information without relying on the framing provided by the embedding protocol or the storage system.

* They are based on media types {{-media-types}}, which allows the cost of their registration to be spread across numerous usage scenarios.

A protocol designer could use these formats, for example, to convey
Evidence, Endorsements and Reference Values in certificates and CRLs
extensions ({{DICE-arch}}), to embed Attestation Results or Evidence as
first-class authentication credentials in TLS handshake messages
{{-tls-a}}, to transport attestation-related payloads in RESTful APIs,
or for stable storage of Attestation Results in the form of file system
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

A further CMW "collection" type that holds together multiple CMW items is defined in {{cmw-coll}}.

The collected CDDL is in {{collected-cddl}}.

## CMW Array {#type-n-val}

The CMW array format is defined in {{fig-cddl-array}}.

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
both Reference Values and Endorsements within the same `application/signed-corim+cbor`), or if the same profile identifier is
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

## CMW Collections {#cmw-coll}

Layered Attesters and composite devices ({{Sections 3.2 and 3.3 of -rats-arch}}) generate Evidence that consists of multiple parts.

For example, in data center servers, it is not uncommon for separate attesting environments (AE) to serve a subsection of the entire machine.
One AE might measure and attest to what was booted on the main CPU, while another AE might measure and attest to what was booted on a SmartNIC plugged into a PCIe slot, and a third AE might measure and attest to what was booted on the machine's GPU.

To address the composite Attester use case, this document defines a CMW "collection" as a container that holds several CMW items, each with a label that is unique within the scope of the collection.

The CMW collection ({{fig-cddl-collection}}) is defined as a CBOR map or JSON object with CMW values.
The position of a `cmw` entry in the `cmw-collection` is not significant.
Instead, the labels identify a conceptual message that, in the case of a composite Attester, should typically correspond to a component of a system.
Labels can be strings or integers that serve as a mnemonic for different conceptual messages in the collection.

~~~ cddl
{::include cddl/cmw-collection.cddl}
~~~
{: #fig-cddl-collection artwork-align="left"
   title="CDDL definition of the CMW collection format"}

Although initially designed for the composite Attester use case, the CMW collection can be repurposed for other use cases requiring CMW aggregation.

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
{::include cddl/cmw-example-json-1.diag}
~~~

Note that a CoAP Content-Format number can also be used with the JSON array
form.  That may be the case when it is known that the receiver can handle CoAP
Content-Formats and it is crucial to save bytes.

## CBOR Array {#ex-ca}

~~~ cbor-diag
{::include cddl/cmw-example-cbor-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/cmw-example-cbor-1.pretty}
~~~

Note that a Media-Type-Name can also be used with the CBOR array form,
for example if it is known that the receiver cannot handle CoAP
Content-Formats, or (unlike the case in point) if a CoAP Content-Format
number has not been registrered.

~~~ cbor-diag
{::include cddl/cmw-example-cbor-2.diag}
~~~

## CBOR Tag {#ex-ct}

~~~ cbor-diag
{::include cddl/cmw-example-cbor-tag-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/cmw-example-cbor-tag-1.pretty}
~~~

## CBOR Array with explicit CM indicator {#ex-ca-ind}

~~~ cbor-diag
{::include cddl/cmw-example-cbor-3.diag}
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

## CBOR Collection

The following example is a CBOR collection that assembles conceptual messages from three attesters: Evidence for attesters A and B and Attestation Result for attester C.

~~~
{::include cddl/collection-example-cbor-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/collection-example-cbor-1.pretty}
~~~

## JSON Collection

The following example is a JSON collection that assembles Evidence from two attesters.

~~~
{::include cddl/collection-example-json-1.diag}
~~~

# Transporting CMW and CMW Collections in X.509 Messages {#x509}

There are cases where CMW and CMW collection payloads need to be transported in PKIX messages, for example in Certificate Signing Requests (CSRs) {{-csr-a}}, or in X.509 Certificates and Certificate Revocation Lists (CRLs) {{DICE-arch}}.

For CMW, Section 6.1.8 of {{DICE-arch}} already defines the ConceptualMessageWrapper format and the associated object identifier.

This section specifies the CMWCollection extension to carry CMW collection objects.

The CMWCollection extension MAY be included in X.509 Certificates, CRLs {{-pkix}}, and CSRs.

The CMWCollection extension MUST be identified by the following object identifier:

~~~asn.1
id-pe-cmw-collection  OBJECT IDENTIFIER ::=
        { iso(1) identified-organization(3) dod(6) internet(1)
          security(5) mechanisms(5) pkix(7) id-pe(1) TBD }
~~~

This extension MUST NOT be marked critical.

The CMWCollection extension MUST have the following syntax:

~~~asn.1
CMWCollection ::= CHOICE {
    json UTF8String,
    cbor OCTET STRING,
}
~~~

The CMWCollection MUST contain the serialized CMW collection object in JSON or CBOR format, using the appropriate CHOICE entry.

## ASN.1 Module {#asn1-x509}

This section provides an ASN.1 module {{X.680}} for the CMWCollection extension, following the conventions established in {{RFC5912}} and {{RFC6268}}.

~~~asn.1
CMWCollectionExtn
  { iso(1) identified-organization(3) dod(6) internet(1)
    security(5) mechanisms(5) pkix(7) id-mod(0)
    id-mod-cmw-collection-extn(TBD) }

DEFINITIONS IMPLICIT TAGS ::=
BEGIN

IMPORTS
  EXTENSION
  FROM PKIX-CommonTypes-2009  -- RFC 5912
    { iso(1) identified-organization(3) dod(6) internet(1)
      security(5) mechanisms(5) pkix(7) id-mod(0)
      id-mod-pkixCommon-02(57) } ;

-- CMWCollection Extension

ext-CMWCollection EXTENSION ::= {
  SYNTAX CMWCollection
  IDENTIFIED BY id-pe-cmw-collection }

-- CMWCollection Extension OID

id-pe-cmw-collection  OBJECT IDENTIFIER  ::=
   { iso(1) identified-organization(3) dod(6) internet(1)
     security(5) mechanisms(5) pkix(7) id-pe(1) TBD }

-- CMWCollection Extension Syntax

CMWCollection ::= CHOICE {
    json UTF8String,
    cbor OCTET STRING,
}

END
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

# Security Considerations {#seccons}

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

## Media Types

IANA is requested to add the following media types to the "Media Types" registry {{!IANA.media-types}}.

| Name | Template | Reference |
|-----------------|-------------------------|-----------|
| `cmw+cbor` | `application/cmw+cbor` | {{type-n-val}} and {{cbor-tag}} of {{&SELF}} |
| `cmw+json` | `application/cmw+json` | {{type-n-val}} of {{&SELF}} |
| `cmw-collection+cbor` | `application/cmw-collection+cbor` | {{cmw-coll}} of {{&SELF}} |
| `cmw-collection+json` | `application/cmw-collection+json` | {{cmw-coll}} of {{&SELF}} |
{: #tab-mt-regs title="CMW Media Types"}

### `application/cmw+cbor`

{:compact}
Type name:
: application

Subtype name:
: cmw+cbor

Required parameters:
: n/a

Optional parameters:
: n/a

Encoding considerations:
: binary (CBOR)

Security considerations:
: {{seccons}} of {{&SELF}}

Interoperability considerations:
: n/a

Published specification:
: {{&SELF}}

Applications that use this media type:
: Attesters, Verifiers, Endorsers and Reference-Value providers, Relying Parties that need to transfer CMW payloads over HTTP(S), CoAP(S), and other transports.

Fragment identifier considerations:
: The syntax and semantics of fragment identifiers are as specified for "application/cbor". (No fragment identification syntax is currently defined for "application/cbor".)

Person & email address to contact for further information:
: RATS WG mailing list (rats@ietf.org)

Intended usage:
: COMMON

Restrictions on usage:
: none

Author/Change controller:
: IETF

Provisional registration:
: no

### `application/cmw+json`

{:compact}
Type name:
: application

Subtype name:
: cmw+json

Required parameters:
: n/a

Optional parameters:
: n/a

Encoding considerations:
: binary (JSON is UTF-8-encoded text)

Security considerations:
: {{seccons}} of {{&SELF}}

Interoperability considerations:
: n/a

Published specification:
: {{&SELF}}

Applications that use this media type:
: Attesters, Verifiers, Endorsers and Reference-Value providers, Relying Parties that need to transfer CMW payloads over HTTP(S), CoAP(S), and other transports.

Fragment identifier considerations:
: The syntax and semantics of fragment identifiers are as specified for "application/json". (No fragment identification syntax is currently defined for "application/json".)

Person & email address to contact for further information:
: RATS WG mailing list (rats@ietf.org)

Intended usage:
: COMMON

Restrictions on usage:
: none

Author/Change controller:
: IETF

Provisional registration:
: no

### `application/cmw-collection+cbor`

{:compact}
Type name:
: application

Subtype name:
: cmw-collection+cbor

Required parameters:
: n/a

Optional parameters:
: n/a

Encoding considerations:
: binary (CBOR)

Security considerations:
: {{seccons}} of {{&SELF}}

Interoperability considerations:
: n/a

Published specification:
: {{&SELF}}

Applications that use this media type:
: Attesters, Verifiers, Endorsers and Reference-Value providers, Relying Parties that need to transfer collections of CMW payloads over HTTP(S), CoAP(S), and other transports.

Fragment identifier considerations:
: The syntax and semantics of fragment identifiers are as specified for "application/cbor". (No fragment identification syntax is currently defined for "application/cbor".)

Person & email address to contact for further information:
: RATS WG mailing list (rats@ietf.org)

Intended usage:
: COMMON

Restrictions on usage:
: none

Author/Change controller:
: IETF

Provisional registration:
: no

### `application/cmw-collection+json`

{:compact}
Type name:
: application

Subtype name:
: cmw-collection+json

Required parameters:
: n/a

Optional parameters:
: n/a

Encoding considerations:
: binary (JSON is UTF-8-encoded text)

Security considerations:
: {{seccons}} of {{&SELF}}

Interoperability considerations:
: n/a

Published specification:
: {{&SELF}}

Applications that use this media type:
: Attesters, Verifiers, Endorsers and Reference-Value providers, Relying Parties that need to transfer collections of CMW payloads over HTTP(S), CoAP(S), and other transports.

Fragment identifier considerations:
: The syntax and semantics of fragment identifiers are as specified for "application/json". (No fragment identification syntax is currently defined for "application/json".)

Person & email address to contact for further information:
: RATS WG mailing list (rats@ietf.org)

Intended usage:
: COMMON

Restrictions on usage:
: none

Author/Change controller:
: IETF

Provisional registration:
: no

## New SMI Numbers Registrations

IANA is requested to assign an object identifier (OID) for the CMWCollection extension defined in {{x509}} in the "Certificate Extension" sub-registry of the "SMI Numbers" {{!IANA.smi-numbers}} registry.

IANA is requested to assign an object identifier (OID) for the ASN.1 Module defined in {{asn1-x509}} in the "Module Identifier" sub-registry of the "SMI Numbers" {{!IANA.smi-numbers}} registry.

--- back

## Collected CDDL {#collected-cddl}

~~~ cddl
{::include cddl/cmw.cddl}
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
The definition of a CMW collection has been modelled on a proposal originally made by Simon Frost for an EAT-based Evidence collection type.  The CMW collection intentionally attains binary compatibility with Simon's design and aims at superseding it by also generalizing on the allowed Evidence formats.

[^note]: Note:
[^issue]: Open issue:
[^rfced]: RFC Editor:
