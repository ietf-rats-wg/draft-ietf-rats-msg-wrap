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
keyword: [ evidence, attestation results, endorsements, reference values ]

stand_alone: yes
smart_quotes: no
pi: [toc, sortrefs, symrefs]

author:
 - name: Henk Birkholz
   organization: Fraunhofer SIT
   email: henk.birkholz@ietf.contact
 - name: Ned Smith
   organization: Independent
   email: ned.smith.ietf@outlook.com
 - name: Thomas Fossati
   organization: Linaro
   email: thomas.fossati@linaro.org
 - name: Hannes Tschofenig
   org: University of Applied Sciences Bonn-Rhein-Sieg
   abbrev: H-BRS
   email: Hannes.Tschofenig@gmx.net
 - name: Dionna Glaze
   organization: Google LLC
   email: dionnaglaze@google.com

contributor:
 - name: Laurence Lundblade
   organization: Security Theory LLC
   email: lgl@securitytheory.com
   contribution: Laurence made significant contributions to enhancing the security requirements and considerations for Collection CMWs.

normative:
  RFC3986: uri
  RFC4648: base64
  RFC5280: pkix
  RFC6838: media-types
  RFC7252: coap
  RFC7515: jws
  RFC7519: jwt
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
  RFC3647: pkix-cps
  RFC5912: pkix-mods
  RFC6268: more-pkix-mods
  RFC7942: impl-status
  RFC9193: senml-cf
  STD96:
    -: cose
    =: RFC9052
  RFC9334: rats-arch
  RFC9711: rats-eat
  RFC9782: rats-eat-mt
  I-D.ietf-rats-ear: rats-ear
  RFC9781: rats-uccs
  I-D.fossati-tls-attestation: tls-a1
  I-D.fossati-seat-expat: tls-a2
  I-D.ietf-lamps-csr-attestation: csr-a
  I-D.ietf-rats-corim: rats-corim
  DICE-arch:
    author:
      org: "Trusted Computing Group"
    title: "DICE Attestation Architecture"
    target: https://trustedcomputinggroup.org/wp-content/uploads/DICE-Attestation-Architecture-Version-1.1-Revision-18_pub.pdf
    date: January, 2024

entity:
  SELF: "RFCthis"

--- abstract

The Conceptual Messages introduced by the RATS architecture (RFC 9334) are protocol-agnostic data units that are conveyed between RATS roles during remote attestation procedures.
Conceptual Messages describe the meaning and function of such data units within RATS data flows without specifying a wire format, encoding, transport mechanism, or processing details.
The initial set of Conceptual Messages is defined in Section 8 of RFC 9334 and includes Evidence, Attestation Results, Endorsements, Reference Values, and Appraisal Policies.

This document introduces the Conceptual Message Wrapper (CMW) that provides a common structure to encapsulate these messages.
It defines a dedicated CBOR tag, corresponding JSON Web Token (JWT) and CBOR Web Token (CWT) claims, and an X.509 extension.

This allows CMWs to be used in CBOR-based protocols, web APIs using JWTs and CWTs, and PKIX artifacts like X.509 certificates.
Additionally, the draft defines a media type and a CoAP content format to transport CMWs over protocols like HTTP, MIME, and CoAP.

The goal is to improve the interoperability and flexibility of remote attestation protocols.
Introducing a shared message format such as CMW enables consistent support for different attestation message types, evolving message
serialization formats without breaking compatibility, and avoiding the need to redefine how messages are handled within each protocol.

--- middle

# Introduction

The Conceptual Messages introduced by the Remote ATtestation procedureS (RATS) architecture {{-rats-arch}} are protocol-agnostic data units that are conveyed between RATS roles during remote attestation procedures.
Conceptual Messages describe the meaning and function of such data units within RATS data flows without specifying a wire format, encoding, transport mechanism, or processing details.
The initial set of Conceptual Messages is defined in {{Section 8 of -rats-arch}} and includes Evidence, Attestation Results, Endorsements, Reference Values, and Appraisal Policies.

Each conceptual message can have multiple claims encoding and serialization
formats ({{Section 9 of -rats-arch}}). Throughout their lifetime, RATS
conceptual messages are typically transported over different protocols.
For example,

- In a "background check" topology, Evidence (e.g., EAT {{-rats-eat}}) first flows from
the Attester to the Relying Party and then from the Relying Party to the Verifier,
each leg following a separate protocol path.

~~~~ aasvg
                            .------------.
                            |  Verifier  |
                            '------------'
                                ^
                                | EAT
                                | over
                                | REST API
.------------.              .---|--------.
|  Attester  +------------->|--'      RP |
'------------' EAT over TLS '------------'
~~~~
{: artwork-align="center"}

- In a "passport" topology, an attestation result payload (e.g., EAT Attestation Result (EAR) {{-rats-ear}})
is initially sent from the Verifier to the Attester, and later,
via a different channel, from the Attester to the Relying Party.

~~~~ aasvg
 .------------.
 |  Verifier  |
 '--------+---'
      EAR |
     over |
 REST API |
          v
 .------------.              .------------.
 |  Attester  +------------->|     RP     |
 '------------' EAR over TLS '------------'
~~~~
{: artwork-align="center"}

By using the CMW format outlined in this document, protocol designers can avoid the need
to update protocol specifications to accommodate different conceptual messages and
serialization formats used by various attestation technologies. This approach streamlines
the implementation process for developers, enabling easier support for diverse attestation
technologies. For instance, a Relying Party application implementer does not need to parse
attestation-related messages, such as Evidence from Attesters on IoT devices with Trusted
Platform Modules (TPM) or servers using confidential computing hardware like Intel Trust
Domain Extensions (TDX). Instead, they can leverage the CMW format, remaining agnostic
to the specific attestation technology.

A further design goal is extensibility.
This means that adding support for new conceptual messages and new attestation technologies should not change the core of the processor, and that a CMW stack can be designed to offer a plug-in interface for both encoding and decoding.
To achieve this, the format must provide consistent message encapsulation and explicit typing.
These features allow for selecting the appropriate message handler based on its type identifier.
An opaque message can then be passed between the core and the handler.

This document defines two encapsulation formats for RATS conceptual
messages that aim to achieve the goals stated above.

These encapsulation formats have been specifically designed to possess the following characteristics:

* They are self-describing, which means that they can convey precise typing information without relying on the framing provided by the embedding protocol or the storage system.

* They are based on media types {{-media-types}}, which allows the cost of their registration to be spread across numerous usage scenarios.

A protocol designer could use these formats, for example, to convey
Evidence, Endorsements and Reference Values in certificates and CRLs
extensions ({{DICE-arch}}), to embed Attestation Results or Evidence as
first-class authentication credentials in TLS handshake messages
{{-tls-a1}} {{-tls-a2}}, to transport attestation-related payloads in RESTful APIs,
or for stable storage of Attestation Results in the form of file system
objects.

This document also defines corresponding CBOR tag, JSON Web Tokens (JWT) and CBOR Web Tokens (CWT) claims, as well as an X.509 extension.
These allow embedding the wrapped conceptual messages into CBOR-based protocols, web APIs, and PKIX formats and protocols.
In addition, a Media Type and a CoAP Content-Format are defined for transporting CMWs in HTTP, MIME, CoAP and other Internet protocols.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

In this document, CDDL {{-cddl}} {{-cddlplus}} is used to describe the
data formats.

The reader is assumed to be familiar with the vocabulary and concepts
defined in {{-rats-arch}}.

This document reuses the terms defined in {{Section 2 of -senml-cf}}
(e.g., "Content-Type").

# Conceptual Message Wrappers

A RATS Conceptual Message Wrapper (CMW) has a tree structure.
Leaf nodes are of type "Record" ({{type-n-val}}), or "Tag" ({{cbor-tag}}).
Intermediate nodes are of type "Collection" ({{cmw-coll}}); they hold together multiple CMW items.

The following snippet outlines the productions associated with the top-level types.

~~~ cddl
{::include cddl/cmw-start.cddl}
~~~

The complete CDDL can be found in {{collected-cddl}}.

{{webtokens}} and {{x509}} describe the transport of CMWs using CBOR and JSON Web Tokens and PKIX formats, including Certificate Signing Requests (CSRs), X.509 Certificates, and Certificate Revocation Lists (CRLs).

This document only defines an encapsulation, not a security format.
It is the responsibility of the Attester to ensure that the CMW contents have the necessary security protection.
Security considerations are discussed in {{seccons}}.

## Record CMW {#type-n-val}

The format of the Record CMW is shown in {{fig-cddl-record}}.
The JSON {{-json}} and CBOR {{-cbor}} representations are provided separately.
Both the `json-record` and `cbor-record` have the same fields except for slight differences in the types discussed below.

~~~ cddl
{::include cddl/cmw-record.cddl}
~~~
{: #fig-cddl-record artwork-align="left"
   title="CDDL definition of the Record CMW"}

Each contains two or three members:

{: vspace="0"}

`type`:
: Either a text string representing a Content-Type (e.g., an EAT media type
{{-rats-eat-mt}}) or an unsigned integer corresponding to a CoAP Content-Format
ID ({{Section 12.3 of -coap}}).
The latter is not used in the JSON serialization.

`value`:
: The RATS conceptual message serialized according to the
value defined in the type member.
When using JSON, the value field MUST be encoded as Base64 using the URL and
filename safe alphabet ({{Section 5 of -base64}}) without padding.
This always applies, even if the conceptual message format is already textual (e.g., a JWT EAT).
When using CBOR, the value field MUST be encoded as a CBOR byte string.

`ind`:
: An optional bitmap with a maximum size of 4 bytes that indicates which conceptual message types are
carried in the `value` field.  Any combination (i.e., any value between
1 and 2<sup>32</sup>-1 inclusive) is allowed.  Only five bits are registered in this document, so, the acceptable values are currently limited to 1 to 31.  This is useful only if the `type` is
potentially ambiguous and there is no further context available to the
CMW consumer to decide.  For example, this might be the case if the base
media type is not profiled (e.g., `application/eat+cwt`), if the `value`
field contains multiple conceptual messages with different types (e.g.,
both Reference Values and Endorsements within the same `application/rim+cose`), or if the same profile identifier is
shared by different conceptual messages.
The value MUST be non-zero. The absence of conceptual message indicator information is indicated by omitting the `ind` field entirely.
For further details, see {{cm-type}}.

### CM Type {#cm-type}

The `cm-type` type is the control type for the `ind` field.
As such, it indicates which bits are allowed to be set in the `ind` byte string.

~~~ cddl
{::include cddl/cm-type.cddl}
~~~
{: #fig-cddl-cm-type artwork-align="left"
   title="CDDL definition of the CM Type"}

The `cm-type` as defined by this document has five allowed values: Reference Values, Endorsements, Evidence, Attestation Results, and Appraisal Policy, as defined in {{Section 8 of -rats-arch}}.
Note that that an Appraisal Policy may refer to the appraisal of Evidence or Attestation Results, depending on whether the consumer of the conceptual message is a Verifier or a Relying Party.

Future specifications that extend the RATS Conceptual Messages set can add new values to the `cm-type` using the process defined in {{iana-ind-ext}}.

## Tag CMW {#cbor-tag}

Tag CMWs derive their tag numbers from a corresponding CoAP Content-Format ID using the `TN()` transform defined in {{Appendix B of RFC9277}}.
Such CBOR tag numbers are in range \[1668546817, 1668612095\].

The RATS conceptual message is first serialized according to the Content-Format ID and then encoded as a CBOR byte string, to which the TN-derived tag number is prepended.

The Tag CMW is defined in {{fig-cddl-cbor-tag}} using two different macros.
One for CBOR-encoded types, the other for all other types.
Both macros take the CBOR tag number `tn` as a parameter.
The `tag-cm-cbor` macro takes the CDDL definition of the associated conceptual message `fmt` as a second parameter.

~~~ cddl
{::include cddl/cmw-cbor-tag.cddl}
~~~
{: #fig-cddl-cbor-tag artwork-align="left"
   title="CDDL definition of the Tag CMW macros"}

### How To Plug in a New Tag CMW

To plug a new Tag CMW into the CDDL defined in {{collected-cddl}}, the `$cbor-tag` type socket must be extended with a new instance of the Tag CMW macro (i.e., one of `tag-cm-cbor` or `tag-cm-data`).

For instance, if a conceptual message of type `my-evidence` has a TN-derived CBOR tag `1668576819`, `$cbor-tag` would be extended as follows:


~~~ cddl
{::include cddl/cmw-example-tag-1668576819-def.cddl}
~~~

Instead, if a (non-CBOR) conceptual message has a TN-derived CBOR tag `1668576935`, `$cbor-tag` would be extended as follows:

~~~ cddl
{::include cddl/cmw-example-tag-1668576935-def.cddl}
~~~

Note that since this specification defines no Tag CMW, the socket is currently empty.

## Collection CMW {#cmw-coll}

Layered Attesters and composite devices ({{Sections 3.2 and 3.3 of -rats-arch}}) generate Evidence that consists of multiple parts.
For example, in data center servers, it is not uncommon for separate attesting environments (AE) to serve a subsection of the entire machine.
One AE might measure and attest to what was booted on the main CPU, while another AE might measure and attest to what was booted on a SmartNIC plugged into a PCIe slot, and a third AE might measure and attest to what was booted on the machine's GPU.
To allow aggregation of multiple, potentially non-homogeneous evidence formats collected from different AEs, this document defines a Collection CMW as a container that holds several CMW items, each with a label that is unique within the scope of the Collection.

Although originally designed to support layered Attester and composite device use cases, the Collection CMW can be adapted for other scenarios that require the aggregation of RATS conceptual messages.
For instance, Collections may be used to group Endorsements, Reference Values, Attestation Results, and more.
A single Collection CMW can contain a mix of different message types, and it can also be used to carry messages related to multiple devices simultaneously.

The Collection CMW ({{fig-cddl-collection}}) is defined as a CBOR map or JSON object containing CMW values.
The position of a `cmw` entry in the `cmw-collection` is not significant.
Labels can be strings (or integers in the CBOR serialization) that serve as a mnemonic for different conceptual messages in the Collection.

A Collection MUST have at least one CMW entry.

The `"__cmwc_t"` key is reserved for associating an optional type with the overall Collection and MUST NOT be used for any purpose other than described here.

The value of the `"__cmwc_t"` key is either a Uniform Resource Identifier (URI) or an object identifier (OID).
The OID is always absolute and never relative.
The URI MUST be in the absolute form ({{Section 4.3 of -uri}}).

The `"__cmwc_t"` key functions similar to an EAT profile claim (see {{Section 4.3.2 of -rats-eat}}), but at a higher level.
It can be used to indicate basics like CBOR serialization and COSE algorithms just as a profile in EAT does.
It provides a namespace in which the collection labels are interpreted.
At the higher level, it can be used to describe the allowed CMW collection assembly (this is somewhat parallel to the way EAT profiles indicate which claims are required and/or allowed).
For an example of a `"__cmwc_t"` that is defined for a bundle of endorsements and reference values, see {{Section 4.3.1 of -rats-corim}}.

Since the Collection CMW is recursive (a Collection CMW is itself a CMW), implementations MAY limit the allowed depth of nesting.

~~~ cddl
{::include cddl/cmw-collection.cddl}
~~~
{: #fig-cddl-collection artwork-align="left"
   title="CDDL definition of the Collection CMW"}

## Demuxing

The split in the JSON/CBOR decoding path is expected to occur via the media type or content format (see {{iana-mt}} and {{iana-cf}}, respectively), or via the container context of the embedded CMW (see {{iana-cwt}} and {{iana-jwt}} for CWT/JWT, and {{iana-smi}} for X.509).

The following pseudocode illustrates how a one-byte look-ahead is sufficient to determine how to decode the remaining byte buffer.

~~~
func CMWTypeDemux(b []byte) CMWType {
  if len(b) == 0 {
    return Unknown
  }

  switch b[0] {
  case 0x82: // 2-elements cbor-record (w/o ind field)
  case 0x83: // 3-elements cbor-record (w/ ind field)
  case 0x9f: // start of cbor-record using indefinite-length encoding
    return CBORRecord
  case 0xda: // tag-cm-cbor (CBOR Tag in the TN range)
    return CBORTag
  case 0x5b: // ASCII '[', start of json-record
    return JSONRecord
  case 0x7b: // ASCII '{', start of json-collection
    return JSONCollection
  case 0xa0..0xbb: // CBOR map start values, start of cbor-collection
  case 0xbf:       // ditto
    return CBORCollection
  }

  return Unknown
}
~~~

This code is provided for informational purposes only.
It is not expected that implementations will follow this demuxing strategy.

# Cryptographic Protection of CMWs {#crypto}

This section highlights a number of mechanisms through which protocol designers can add data origin authentication, integrity, and, if used with a challenge-response protocol, anti-replay protection when employing CMWs.
These properties must be evaluated carefully in the context of the overall security model of the protocol.

## Signing CBOR CMW using COSE Sign1 {#signed-cbor-cmw}

A CBOR CMW can be signed using COSE {{-cose}}.
A `signed-cbor-cmw` is a `COSE_Sign1` with the following layout:

~~~ cddl
{::include cddl/signed-cbor-cmw.cddl}
~~~

The payload MUST be the CBOR-encoded Tag, Record, or Collection CMW.

~~~ cddl
{::include cddl/signed-cbor-cmw-headers.cddl}
~~~

The protected header MUST include the signature algorithm identifier.
The protected header MUST include either the content type `application/cmw+cbor` or the CoAP Content-Format TBD1.
Other header parameters MAY be added to the header buckets, for example a `kid` that identifies the signing key.

## Signing JSON CMW using JWS {#signed-json-cmw}

A JSON CMW can be signed using JSON Web Signature (JWS) {{-jws}}.
A `signed-json-cmw` is a JWS object with the following layout:

~~~ cddl
{::include cddl/signed-json-cmw.cddl}
~~~

The payload MUST be the JSON-encoded Record, or Collection CMW.

~~~ cddl
{::include cddl/signed-json-cmw-headers.cddl}
~~~

The protected header MUST include the signature algorithm identifier.
The protected header MUST include the content type `application/cmw+json`.
Other header parameters MAY be added to the header buckets, for example a `kid` that identifies the signing key.

For clarity, the above uses the Flattened JSON Serialization ({{Section 7.2.2 of -jws}}).
However, the Compact Serialization ({{Section 3.1 of -jws}}) can also be used.

## Transporting CMW in COSE and JOSE Web Tokens {#webtokens}

To facilitate the embedding of CMWs in CBOR-based protocols and web APIs, this document defines two `"cmw"` claims for use with JSON Web Tokens (JWT) and CBOR Web Tokens (CWT).

The definitions for these claims can be found in {{iana-jwt}} and {{iana-cwt}}, respectively.

### Encoding Requirements

A Collection CMW carried in a `"cmw"` JWT claim MUST be a `json-collection`.
A Collection CMW carried in a `"cmw"` CWT claim MUST be a `cbor-collection`.

A Record CMW carried in a `"cmw"` JWT claim MUST be a `json-record`.
A Record CMW carried in a `"cmw"` CWT claim MUST be a `cbor-record`.

## Transporting CMW in PKIX Formats {#x509}

CMW may need to be transported in PKIX formats, such as Certificate Signing Requests (CSRs) or in X.509 Certificates and Certificate Revocation Lists (CRLs).

The use of CMW in CSRs is documented in {{-csr-a}}, while one of the possible applications in X.509 Certificates and CRLs is detailed in Section 6.1 of {{DICE-arch}}.

This section outlines the CMW extension designed to carry CMW objects.
{{privcons}} discusses some privacy considerations related to the transport of CMW in X.509 formats.

The CMW extension MAY be included in X.509 Certificates, CRLs {{-pkix}}, and CSRs.

The CMW extension MUST be identified by the following object identifier:

~~~asn.1
id-pe-cmw  OBJECT IDENTIFIER ::=
        { iso(1) identified-organization(3) dod(6) internet(1)
          security(5) mechanisms(5) pkix(7) id-pe(1) 35 }
~~~

This extension SHOULD NOT be marked critical.
In cases where the wrapped Conceptual Message is essential for granting resource access, and there is a risk that legacy relying parties would bypass crucial controls, it is acceptable to mark the extension as critical.

The CMW extension MUST have the following syntax:

~~~asn.1
CMW ::= CHOICE {
    json UTF8String,
    cbor OCTET STRING
}
~~~

The CMW MUST include the serialized CMW object in either JSON or CBOR format, utilizing the appropriate CHOICE entry.

The DER-encoded CMW is the value of the OCTET STRING for the extnValue field of the extension.

### ASN.1 Module {#asn1-x509}

This section provides an ASN.1 module {{X.680}} for the CMW extension, following the conventions established in {{-pkix-mods}} and {{-more-pkix-mods}}.

~~~asn.1
CMWExtn
  { iso(1) identified-organization(3) dod(6) internet(1)
    security(5) mechanisms(5) pkix(7) id-mod(0)
    id-mod-cmw-extn(TBD) }

DEFINITIONS IMPLICIT TAGS ::=
BEGIN

IMPORTS
  EXTENSION
  FROM PKIX-CommonTypes-2009  -- RFC 5912
    { iso(1) identified-organization(3) dod(6) internet(1)
      security(5) mechanisms(5) pkix(7) id-mod(0)
      id-mod-pkixCommon-02(57) } ;

-- CMW Extension

ext-CMW EXTENSION ::= {
  SYNTAX CMW
  IDENTIFIED BY id-pe-cmw }

-- CMW Extension OID

id-pe-cmw  OBJECT IDENTIFIER  ::=
   { iso(1) identified-organization(3) dod(6) internet(1)
     security(5) mechanisms(5) pkix(7) id-pe(1) 35 }

-- CMW Extension Syntax

CMW ::= CHOICE {
    json UTF8String,
    cbor OCTET STRING
}

END
~~~

### Compatibility with Trusted Computing Group (TCG) `ConceptualMessageWrapper`

Section 6.1.8 of {{DICE-arch}} specifies the ConceptualMessageWrapper (CMW) format and its corresponding object identifier.
The CMW format outlined in {{DICE-arch}} permits only a subset of the CMW grammar defined in this document.
In particular, the Collection format cannot be encoded using TCG CMWs.

# Examples

The (equivalent) examples in {{ex-ja}}, {{ex-ca}}, and {{ex-ct}} assume that
the Media-Type-Name `application/vnd.example.rats-conceptual-msg` has been
registered alongside a corresponding CoAP Content-Format ID `30001`.  The
CBOR tag `1668576935` is derived applying the `TN()` transform as described in
{{cbor-tag}}.

All the examples focus on the wrapping aspects.
The wrapped messages are not instances of real Conceptual Messages.

## JSON-encoded Record {#ex-ja}

~~~ cbor-diag
{::include cddl/cmw-example-1.json}
~~~

## CBOR-encoded Record {#ex-ca}

~~~ cbor-diag
{::include cddl/cmw-example-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/cmw-example-1.pretty}
~~~

Note that a Media-Type-Name can also be used with the CBOR-encoded Record form,
for example if it is known that the receiver cannot handle CoAP
Content-Formats, or (unlike the case in point) if a CoAP Content-Format
ID has not been registered.

~~~ cbor-diag
{::include cddl/cmw-example-2.diag}
~~~

## CBOR-encoded Tag CMW {#ex-ct}

~~~ cbor-diag
{::include cddl/cmw-example-tag-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/cmw-example-tag-1.pretty}
~~~

## CBOR-encoded Record with explicit CM indicator {#ex-ca-ind}

This is an example of a signed CoRIM (Concise Reference Integrity Manifest) {{-rats-corim}} with an explicit `ind` value of `0b0000_0011` (3), indicating that the wrapped message contains both Reference Values and Endorsements.

~~~ cbor-diag
{::include cddl/cmw-example-3.diag}
~~~

with the following wire representation:

~~~
{::include-fold cddl/cmw-example-3.pretty}
~~~

## CBOR-encoded Collection

The following example is a CBOR-encoded Collection CMW that assembles conceptual messages from three attesters: Evidence for attesters A and B and Attestation Results for attester C.
It is given an explicit `"__cmwc_t"` using the URI form.

~~~
{::include cddl/collection-example-2.diag}
~~~

## JSON-encoded Collection

The following example is a JSON-encoded Collection CMW that assembles Evidence from two attesters.

~~~
{::include cddl/collection-example-2.json}
~~~

## Use in JWT

The following example shows the use of the `"cmw"` JWT claim to transport a Collection CMW in a JWT Claims Set {{-jwt}}:

~~~
{::include cddl/eat-example-1.json}
~~~

# Collected CDDL {#collected-cddl}

This section contains all the CDDL definitions included in this specification.

~~~ cddl
{::include cddl/collected-cddl-autogen.cddl}
~~~

# Implementation Status

[^rfced] Please remove the entire section before publication, as well as the reference to RFC 7942.

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

The organization responsible for these implementations is Project Veraison, a
Linux Foundation project hosted at the Confidential Computing Consortium.

The organisation hosts two libraries which allow encoding, decoding, and
manipulation of CMW payloads: one for the Golang ecosystem
([](https://github.com/veraison/cmw)), and one for Rust
([](https://github.com/veraison/rust-cmw)).
These implementations cover all the features presented in this draft.
The maturity level is alpha.
The license is Apache 2.0.
The developers can be contacted on the Zulip channel:
[](https://veraison.zulipchat.com/#narrow/stream/383526-CMW/).

# Privacy Considerations {#privcons}

The privacy considerations outlined in {{Section 11 of -rats-arch}} are fully applicable.
In particular, when a CMW contains Personally Identifying Information (PII), which is the case for Evidence and sometimes for other conceptual messages as well, care must be taken to prevent unintended recipients from accessing it.
Generally, utilizing secure channels between the parties exchanging CMWs can help address or mitigate these concerns.
A specific scenario arises when a public key certificate is issued based on Evidence information provided by the certificate requestor to the issuing Certification Authority (CA).
For instance, an individual seeking a publicly-trusted code signing certificate may be willing to disclose the details of the hardware where their code signing keys are stored (e.g., HSM model, patch level, etc.).
However, they likely do not want this information to be publicly accessible.
Applications that intend to publicly "broadcast" Evidence claims received from a third party via X.509 Certificates should define a Certificate Practices Statement {{-pkix-cps}} that clearly specifies the circumstances under which the CA can include such data in the issued certificate.
Note that the aforementioned consideration does not apply to cases where X.509 Certificates are explicitly designed as a security envelope for Evidence claims, such as in {{DICE-arch}}.

# Security Considerations {#seccons}

The security considerations discussed in {{Section 12.2 of -rats-arch}} concerning the protection of conceptual messages are fully applicable.
The following subsections provide further elaboration on these points, particularly in relation to Collection CMWs.

## CMW Protection

CMW Records, Tags, and Collections alone do not offer authenticity, integrity protection, or confidentiality.
It is the responsibility of the designer for each use case to determine the necessary security properties and implement them accordingly.

RATS conceptual messages are typically secured using cryptography.
If the messages are already protected, no additional security requirements are imposed by this encapsulation.
If an adversary attempts to modify the payload encapsulation, it will result in incorrect processing of the encapsulated message, leading to an error.
If the messages are not protected, additional security must be added at a different layer.
For example, a `cbor-record` containing an Unprotected CWT Claims Set (UCCS) {{-rats-uccs}} can be signed as described in {{signed-cbor-cmw}}.

{{crypto}} describes a number of methods that can be used to add cryptographic protection to CMW.

## Using Collection CMWs for Evidence of Composite or Layered Devices {#seccons-coll}

When a Collection CMW is used to encapsulate Evidence for composite or layered attestation of a single device, all Evidence messages within the CMW MUST be cryptographically bound together to prevent an attacker from replacing Evidence from a compromised device with that from a non-compromised device.
If the Collection CMW is not protected from tampering by external security measures (such as object security primitives) or internal mechanisms (such as intra-item binding), an attacker could manipulate the Collection's contents to deceive the Verifier into accepting bogus Evidence as genuine.

Authenticity and integrity protection is expected to be provided by the underlying attestation technology.
For example, key material used to sign/bind an entire Collection CMW should be an attestation key, handled as described in {{Section 12.1 of -rats-arch}}.
The binding does not necessarily have to be a signature over the Collection CMW, it might also be achieved through identifiers, linking claims (e.g., nonces) across CMW collection items, signing or hashing between the members of the Collection.
It is the responsibility of the Attester who creates the Collection CMW to ensure that the contents of the Collection are integrity-protected.

## Integrating CMW into Protocols

When CMW is integrated into some hosting protocol (for example, attested CSR {{-csr-a}} or attested TLS {{-tls-a1}} {{-tls-a2}}), it is up to that hosting protocol to describe how CMW is intended to be used and how it fits into the overall security model.

Such an analysis should consider the types of conceptual messages allowed, including the permitted combinations, the protection requirements, the interface with the hosting protocol, and any other security-relevant aspect arising from the interaction between the CMW assembly and the hosting protocol.

# IANA Considerations

[^rfced] Please replace "{{&SELF}}" with the RFC number assigned to this document.

[^rfced] This document uses the CPA (code point allocation) convention described in {{?I-D.bormann-cbor-draft-numbers}}. For each usage of the term "CPA", please remove the prefix "CPA" from the indicated value and replace the residue with the value assigned by IANA; perform an analogous substitution for all other occurrences of the prefix "CPA" in the document. Finally, please remove this note.

## CWT `cmw` Claim Registration {#iana-cwt}

IANA is requested to add a new `cmw` claim to the "CBOR Web Token (CWT) Claims" registry {{IANA.cwt}} as follows:

* Claim Name: cmw
* Claim Description: A RATS Conceptual Message Wrapper
* JWT Claim Name: cmw
* Claim Key: CPA299
* Claim Value Type(s): CBOR map, CBOR array, or CBOR tag
* Change Controller: IETF
* Specification Document(s): {{type-n-val}}, {{cmw-coll}} and {{cbor-tag}} of {{&SELF}}

## JWT `cmw` Claim Registration {#iana-jwt}

IANA is requested to add a new `cmw` claim to the "JSON Web Token Claims" registry of the "JSON Web Token (JWT)" registry group {{IANA.jwt}} as follows:

* Claim Name: cmw
* Claim Description: A RATS Conceptual Message Wrapper
* Change Controller: IETF
* Specification Document(s): {{type-n-val}} and {{cmw-coll}} of {{&SELF}}

## `+jws` Structured Syntax Suffix

IANA is requested to register the `+jws` structured syntax suffix in the "Structured Syntax Suffixes" registry {{!IANA.media-type-structured-suffix}} in the manner described in {{-media-types}}, which can be used to indicate that the media type is encoded as JSON Web Signature (JWS) {{-jws}}.

### Registry Contents

{:compact}
Name:
: JSON Web Signature (JWS)

+suffix:
: +jws

References:
: {{-jws}}

Encoding Considerations:
: binary; values are represented as a JSON Object or as a series of base64url-encoded values each separated from the next by a single period ('.') character.

Interoperability Considerations:
: n/a

Fragment Identifier Considerations:
: n/a

Security Considerations:
: See {{Section 10 of -jws}}

Contact:
: RATS WG mailing list (rats@ietf.org), or IETF Security Area (saag@ietf.org)

Author/Change Controller:
: Remote ATtestation ProcedureS (RATS) Working Group.
  The IETF has change control over this registration.

## RATS Conceptual Message Wrapper (CMW) Indicators Registry {#iana-ind-ext}

This specification defines a new "RATS Conceptual Message Wrapper (CMW) Indicators" registry, with "IETF Review" policy ({{Section 4.8 of -ianacons}}).

The objective is to register CMW Indicator values for all RATS Conceptual Messages (see {{Section 8 of -rats-arch}}).

This registry is to be added to the Remote Attestation Procedures (RATS) registry group at {{!IANA.rats}}.

Indicator values should be added in ascending order, with no gaps between them.

Acceptable values correspond to the RATS conceptual messages defined by the RATS architecture {{-rats-arch}} and any updates to it.

### Structure of Entries

Each entry in the registry must include:

{:vspace}
Indicator value:
: A number corresponding to the bit position in the `ind` bitmap ({{type-n-val}}).

Conceptual Message name:
: A text string describing the RATS conceptual message this indicator corresponds to.

Reference:
: A reference to a document, if available, or the registrant.

The initial registrations for the registry are detailed in {{tab-ind-regs}}.

| Indicator value | Conceptual Message name | Reference |
|-----------------|-------------------------|-----------|
| 0 | Reference Values | {{cm-type}} of {{&SELF}} |
| 1 | Endorsements | {{cm-type}} of {{&SELF}} |
| 2 | Evidence | {{cm-type}} of {{&SELF}} |
| 3 | Attestation Results | {{cm-type}} of {{&SELF}} |
| 4 | Appraisal Policy | {{cm-type}} of {{&SELF}} |
| 5-31 | Unassigned | |
{: #tab-ind-regs title="CMW Indicators Registry Initial Contents"}

### Provisional Registration

[^rfced] Please remove this section before publication, as well as the reference to the provisional CMW Indicators registry.

Before the creation of the registry by IANA, new codepoints can be added to the [provisional CMW Indicators registry](https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/blob/main/provisional/cmw-indicators-registry.md) by following the documented procedure.

{{tab-ind-regs}} will be regularly updated, prior to publication of this specification as an RFC, to match the contents of the provisional registry.

The provisional registry will be discontinued once IANA establishes the permanent registry, which is expected to coincide with the publication of the current document.

## Media Types {#iana-mt}

IANA is requested to add the following media types to the "Media Types" registry {{!IANA.media-types}}.

| Name | Template | Reference |
|-----------------|-------------------------|-----------|
| `cmw+cbor` | `application/cmw+cbor` | {{type-n-val}}, {{cbor-tag}} and {{cmw-coll}} of {{&SELF}} |
| `cmw+json` | `application/cmw+json` | {{type-n-val}} and {{cmw-coll}} of {{&SELF}} |
| `cmw+cose` | `application/cmw+cose` | {{signed-cbor-cmw}} of {{&SELF}} |
| `cmw+jws` | `application/cmw+jws` | {{signed-json-cmw}} of {{&SELF}} |
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
: `cmwc_t` (Collection CMW type in string format.  OIDs must use the
  dotted-decimal notation.  The parameter value is case-insensitive.  It must not be used for CMW that are not Collections.)

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
: `cmwc_t` (Collection CMW type in string format.  OIDs must use the
  dotted-decimal notation.  The parameter value is case-insensitive.  It must not be used for CMW that are not Collections.)

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

### `application/cmw+cose`

{:compact}
Type name:
: application

Subtype name:
: cmw+cose

Required parameters:
: n/a

Optional parameters:
: `cmwc_t` (Collection CMW type in string format.  OIDs must use the
  dotted-decimal notation.  The parameter value is case-insensitive.  It must not be used for CMW that are not Collections.)  Note that the `cose-type` parameter is explicitly not supported, as it is understood to be `"cose-sign1"`.

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
: n/a

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

### `application/cmw+jws`

{:compact}
Type name:
: application

Subtype name:
: cmw+jws

Required parameters:
: n/a

Optional parameters:
: `cmwc_t` (Collection CMW type in string format.  OIDs must use the
  dotted-decimal notation.  The parameter value is case-insensitive.  It must not be used for CMW that are not Collections.)

Encoding considerations:
: 8bit; values are represented as a JSON Object or as a series of base64url-encoded values each separated from the next by a single period ('.') character.

Security considerations:
: {{seccons}} of {{&SELF}}

Interoperability considerations:
: n/a

Published specification:
: {{&SELF}}

Applications that use this media type:
: Attesters, Verifiers, Endorsers and Reference-Value providers, Relying Parties that need to transfer CMW payloads over HTTP(S), CoAP(S), and other transports.

Fragment identifier considerations:
: n/a

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

## CoAP Content-Formats {#iana-cf}

IANA is requested to register the following Content-Format IDs in the "CoAP Content-Formats" registry, within the "Constrained RESTful Environments (CoRE) Parameters" registry group {{!IANA.core-parameters}}:

| Content-Type | Content Coding | ID | Reference |
| application/cmw+cbor | - | TBD1 | {{type-n-val}}, {{cbor-tag}} and {{cmw-coll}} of {{&SELF}} |
| application/cmw+json | - | TBD2 | {{type-n-val}} and {{cmw-coll}} of {{&SELF}} |
| application/cmw+cose | - | TBD3 | {{signed-cbor-cmw}} of {{&SELF}} |
| application/cmw+jws | - | TBD4 | {{signed-json-cmw}} of {{&SELF}} |
{: #tab-cf-regs align="left" title="New CoAP Content Formats"}

If possible, TBD1, TBD2, TBD3 and TBD4 should be assigned in the 256..9999 range.

### Registering new CoAP Content-Formats for Parameterized CMW Media Types

New CoAP Content-Formats can be created based on parameterized instances of the `application/cmw+json`, `application/cmw+cbor`, `application/cmw+cose` and `application/cmw+jws` media types.

When assigning a new CoAP Content-Format ID for a CMW media type that utilizes the `cmwc_t` parameter, the registrar must check (directly or through the Designated Expert) that:

* The corresponding CMW is a Collection ({{cmw-coll}}), and
* The `cmwc_t` value is either a (non-relative) OID or an absolute URI.

### RFC9277 CBOR Tags

[^rfced] Once IANA has allocated TBD1..TBD4, please replace the placeholders in the first column of {{tab-9277-tags}} with the values computed using the TN() formula in {{Appendix B of RFC9277}}.  Similarly, replace the macro parameters in {{fig-9277-tags}}.

Registering the CoAP Content-Formats listed in {{tab-cf-regs}} automatically allocates CBOR Tags in the range \[1668546817, 1668612095\], using the `TN()` transform defined in {{Appendix B of RFC9277}}.
The allocated CBOR Tag numbers and the corresponding data items are listed in {{tab-9277-tags}}.

| Tag Number | Tag Content |
| TN(TBD1) | `bytes .cbor cbor-cmw` |
| TN(TBD2) | bytes-wrapped `json-cmw` |
| TN(TBD3) | `bytes .cbor signed-cbor-cmw` |
| TN(TBD4) | bytes-wrapped `signed-json-cmw` or equivalent using JWS Compact Serialization ({{Section 3.1 of -jws}}) |
{: #tab-9277-tags align="left" title="TN-derived CBOR Tags"}

{{fig-9277-tags}} extends the `$cbor-tag` socket defined in {{cbor-tag}} to add the definitions of the associated Tag CMWs.
Note that CMWs in Tag and Record form are excluded from the productions.
This is because they can already be represented as a CMW, so the extra wrapping would be redundant.

~~~ cddl
{::include cddl/cmw-9277-cbor-tags.cddl}
{::include cddl/cmw-9277-json-tags.cddl}
~~~
{: #fig-9277-tags align="left" title="Tag CMW definitions"}

## New SMI Numbers Registrations {#iana-smi}

IANA has assigned an object identifier (OID) for the CMW extension defined in {{x509}} in the "SMI Security for PKIX Certificate Extension" registry of the "SMI Numbers" {{!IANA.smi-numbers}} registry group as follows:

| Decimal | Description | References |
| 35 | id-pe-cmw | {{x509}} of {{&SELF}} |
{: align="left" title="New CMW Extension OID"}

IANA is requested to assign an object identifier (OID) for the ASN.1 Module defined in {{asn1-x509}} in the "SMI Security for PKIX Module Identifier" registry of the "SMI Numbers" {{!IANA.smi-numbers}} registry group:

| Decimal | Description | References |
| TBD | id-mod-cmw-extn | {{asn1-x509}} of {{&SELF}} |
{: align="left" title="New ASN.1 Module OID"}

--- back

# Registering and Using CMWs

{{fig-howto-cmw}} describes the registration preconditions for using
CMWs in either Record CMW or Tag CMW forms.
When using Collection CMW, the preconditions apply for each entry in the Collection.

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
      |  |   .--------------.   |  |
      |  |  | Automatically  |  |  |
      |  |  | derive CBOR    |  |  |
      |  |  | tag [RFC9277]  |  |  |
      |  |   `------+-------'   |  |
      |  |          |           |  |
      |  |          |           |  |
      |  |          |           |  |
      |  |          v           |  |
      |  |   .----------------. |  |
      |  |  /    Tag CMW     /  |  |
      v  v `----------------'   v  v
  .--------------------------------------.
 /             Record CMW               /
`--------------------------------------'
~~~
{: #fig-howto-cmw artwork-align="center"
   title="How To Create a CMW"}

# Open Issues

The list of currently open issues for this documents can be found at
[](https://github.com/thomas-fossati/draft-ftbs-rats-msg-wrap/issues).

[^rfced] please remove before publication.

# Acknowledgments
{:numbered="false"}

The authors would like to thank
Alexey Melnikov,
Benjamin Schwartz,
Brian Campbell,
Carl Wallace,
Carsten Bormann,
{{{Christian Amsüss}},
Dave Thaler,
Deb Cooley,
{{{Éric Vyncke}}},
{{{Ionuț Mihalcea}}},
Michael B. Jones,
Mike Ounsworth,
Michael StJohns,
Mohit Sethi,
Paul Howard,
Peter Yee,
Russ Housley,
Steven Bellock,
Tim Bray,
Tom Jones,
and
Usama Sardar
for their reviews and suggestions.

The definition of a Collection CMW has been modelled on a proposal originally made by Simon Frost for an EAT-based Evidence collection type.  The Collection CMW aims at superseding it by generalizing the allowed Evidence formats.

[^note]: Note:
[^issue]: Open issue:
[^rfced]: RFC Editor:
