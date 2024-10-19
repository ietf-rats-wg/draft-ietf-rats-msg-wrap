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
   email: henk.birkholz@sit.fraunhofer.de
 - name: Ned Smith
   organization: Intel
   email: ned.smith@intel.com
 - name: Thomas Fossati
   organization: Linaro
   email: thomas.fossati@linaro.org
 - name: Hannes Tschofenig
   email: hannes.tschofenig@gmx.net

contributor:
 - name: Laurence Lundblade
   organization: Security Theory LLC
   email: lgl@securitytheory.com
   contribution: Laurence contributed significant improvements around the security requirements and considerations for CMW collections.

normative:
  RFC4648: base64
  RFC5280: pkix
  RFC5912:
  RFC6268:
  RFC6838: media-types
  RFC7252: coap
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
  RFC7942: impl-status
  RFC9193: senml-cf
  STD96:
    -: cose
    =: RFC9052
  RFC9334: rats-arch
  I-D.ietf-rats-eat: rats-eat
  I-D.ietf-rats-eat-media-type: rats-eat-mt
  I-D.ietf-rats-ar4si: rats-ar4si
  I-D.ietf-rats-uccs: rats-uccs
  I-D.fossati-tls-attestation: tls-a
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

This document defines the RATS conceptual message wrapper (CMW) format, a type of encapsulation format that can be used for any RATS messages, such as Evidence, Attestation Results, Endorsements, and Reference Values.
Additionally, the document describes a collection type that enables the aggregation of one or more CMWs into a single message.

This document also defines corresponding CBOR tag, JSON Web Tokens (JWT) and CBOR Web Tokens (CWT) claims, as well as an X.509 extension.
These allow embedding the wrapped conceptual messages into CBOR-based protocols, web APIs, and PKIX protocols.
In addition, a Media Type and a CoAP Content-Format are defined for transporting CMWs in HTTP, MIME, CoAP and other Internet protocols.

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

This document also defines corresponding CBOR tag, JSON Web Tokens (JWT) and CBOR Web Tokens (CWT) claims, as well as an X.509 extension.
These allow embedding the wrapped conceptual messages into CBOR-based protocols, web APIs, and PKIX protocols.
In addition, a Media Type and a CoAP Content-Format are defined for transporting CMWs in HTTP, MIME, CoAP and other Internet protocols.

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

1. A CMW using a CBOR or JSON record ({{type-n-val}});
1. A CMW based on CBOR tags ({{cbor-tag}}).

A further CMW "collection" type that holds together multiple CMW items is defined in {{cmw-coll}}.

A CMW "tunnel" type is also defined in {{cmw-tunnel}} to allow transporting CBOR CMWs in JSON collections and vice-versa.

The collected CDDL is in {{collected-cddl}}.

This document only defines an encapsulation, not a security format.
It is the responsibility of the Attester to ensure that the CMW contents have the necessary security protection.
Security considerations are discussed in {{seccons}}.

## CMW Record {#type-n-val}

The format of the CMW record is shown in {{fig-cddl-record}}.
The JSON {{-json}} and CBOR {{-cbor}} representations are provided separately.
Both the `json-record` and `cbor-record` have the same fields except for slight differences in the types discussed below.


~~~ cddl
{::include cddl/cmw-record.cddl}
~~~
{: #fig-cddl-record artwork-align="left"
   title="CDDL definition of the Record format"}

Each contains two or three members:

{: vspace="0"}

`type`:
: Either a text string representing a Content-Type (e.g., an EAT media type
{{-rats-eat-mt}}) or an unsigned integer corresponding to a CoAP Content-Format
number ({{Section 12.3 of -coap}}).
The latter MUST NOT be used in the JSON serialization.

`value`:
: The RATS conceptual message serialized according to the
value defined in the type member.
When using JSON, the value field MUST be encoded as Base64 using the URL and
filename safe alphabet ({{Section 5 of -base64}}) without padding.
This always applies, even if the conceptual message format is already textual (e.g., a JWT EAT).
When using CBOR, the value field MUST be encoded as a CBOR byte string.

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


## CMW CBOR Tags {#cbor-tag}

CBOR Tags used as CMW may be derived from CoAP Content-Format numbers.
If a CoAP content format exists for a RATS conceptual message, the
`TN()` transform defined in {{Appendix B of RFC9277}} can be used to
derive a corresponding CBOR tag in range \[1668546817, 1668612095\].

The RATS conceptual message is first serialized according to the
Content-Format number associated with the CBOR tag and then encoded as a
CBOR byte string, to which the tag is prepended.

The CMW CBOR Tag is defined in {{fig-cddl-cbor-tag}} as a macro with two parameters:

* `tn`, the CBOR tag number
* `$fmt`, the definition of the associated conceptual message

~~~ cddl
{::include cddl/cmw-cbor-tag.cddl}
~~~
{: #fig-cddl-cbor-tag artwork-align="left"
   title="CDDL definition of the CBOR Tag format macro"}

To add a new CMW, the `$cbor-tag` type socket is extended with a new instance of the CMW CBOR Tag macro.
For example, to associate conceptual messages of type `my-evidence` with CBOR Tag `1668576819`, one would extend `$cbor-tag` as follows:

~~~ cddl
{::include cddl/cmw-example-tag-1668576819-def.cddl}
~~~

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

## CMW Collections {#cmw-coll}

Layered Attesters and composite devices ({{Sections 3.2 and 3.3 of -rats-arch}}) generate Evidence that consists of multiple parts.
For example, in data center servers, it is not uncommon for separate attesting environments (AE) to serve a subsection of the entire machine.
One AE might measure and attest to what was booted on the main CPU, while another AE might measure and attest to what was booted on a SmartNIC plugged into a PCIe slot, and a third AE might measure and attest to what was booted on the machine's GPU.
To allow aggregation of multiple, potentially non-homogeneous evidence formats collected from different AEs, this document defines a CMW "collection" as a container that holds several CMW items, each with a label that is unique within the scope of the collection.

Even though initially designed to support the layered Attester and composite device use cases, the CMW collection can be repurposed for other use cases requiring aggregation of RATS conceptual messages.
For example, collections may be used to carry groups of Endorsements or Reference Values, Attestation Results, and so on.
One CMW collection can be a mixture of different types of messages.
One CMW collection can be used to carry messages related to more than one device at a time.

The CMW collection ({{fig-cddl-collection}}) is defined as a CBOR map or JSON object with CMW values, either native or "tunnelled" ({{cmw-tunnel}}).
The position of a `cmw` entry in the `cmw-collection` is not significant.
Labels can be strings (or integers in the CBOR serialization) that serve as a mnemonic for different conceptual messages in the collection.

The `"__cmwc_t"` key is reserved for associating an optional type to the overall collection and MUST NOT be used for a label.
The collection type is either a Uniform Resource Identifier (URI) or an object identifier (OID).
The OID is always absolute and never relative.

Since the collection type is recursive, implementations may limit the allowed depth of nesting.

~~~ cddl
{::include cddl/cmw-collection.cddl}
~~~
{: #fig-cddl-collection artwork-align="left"
   title="CDDL definition of the CMW collection format"}

CMW itself provides no facilities for authenticity, integrity protection, privacy or attestation security.
It is up to the designer of each use case to understand the security properties necessary and add them around the collection.
A secure channel (e.g., using TLS) or some form of object security (e.g., using JWT) may be sufficient, but not always.

When a CMW is used to carry Evidence for composite or layered attestation of a single device, all components within the CMW must be cryptographically bound to prevent an attacker from replacing compromised Evidence with that of a non-compromised device. The protection of authenticity and integrity MUST be provided by the attestation technology. For additional security considerations related to collections, refer to {{seccons-coll}}.

### Relation to EAT `submods`

EAT submods ({{Section 4.2.18 of -rats-eat}}) provide a facility for aggregating attestation that has built-in security and will be suitable for some of the same attestation Evidence use cases covered by CMW collections.
However, compared to CMW collections, EAT submods are limited in two ways:

1. EAT {{-rats-eat}} allows carrying non-EAT-formatted types by augmenting the $EAT-CBOR-Tagged-Token socket or the $JSON-Selector socket. However, these need to be specified in subsequent standard documents updating the EAT specification,
2. Their top-down structure does not align well with the bottom-up approach layered attesters use to build the chain of trust, making them not ideal for modelling layered attestation.

### CMW Collections' role in composite Attester topology

A CMW Collection's tree structure is not required to be a spanning tree of the system's composite Attester topology.
If the labels carry semantic content for a Verifier (e.g. to improve Verifier performance or aid human comprehension), the collection SHOULD be integrity protected.
For example, the collection can be integrity protected by including it in a signed token such as a CWT or JWT.

### CMW Tunnel {#cmw-tunnel}

The CMW tunnel type ({{fig-cddl-tunnel}}) allows for moving a CMW in one serialization format, either JSON or CBOR, into a collection that uses the opposite serialization format.

Both tunnel types are arrays with two elements.
The first element, a fixed text string starting with a `#`, acts as a sentinel value.
The `#`, which is not an acceptable start symbol for the `Content-Type` production ({{collected-cddl}}), makes it possible to disambiguate a CMW tunnel from a CMW record.

~~~ cddl
{::include cddl/cmw-tunnel.cddl}
~~~
{: #fig-cddl-tunnel artwork-align="left"
   title="CDDL definition of the CMW tunnel format"}

The conversion algorithms are described in the following subsections.

#### CBOR-to-JSON

The CBOR byte string of the serialised CBOR CMW is encoded as Base64 using the URL and filename safe alphabet ({{Section 5 of -base64}}) without padding.
The obtained string is added as the second element of the `c2j-tunnel` array.
The `c2j-tunnel` array is serialized as JSON.

#### JSON-to-CBOR

The UTF-8 string of the serialized JSON CMW is encoded as a CBOR byte string (Major type 2).
The byte string is added as the second element of the `j2c-tunnel` array.
The `j2c-tunnel` array is serialized as CBOR.

## Decapsulation Algorithm

Once any external framing is removed (for example, if the CMW is carried in a certificate extension), the CMW decoder performs a 1-byte lookahead to determine how to decode the remaining byte buffer.
The following pseudo-code illustrates this process:

~~~
func CMWTypeDemux(b []byte) (CMW, error) {
  if len(b) == 0 {
    return Unknown
  }

  if b[0] == 0x82 || b[0] == 0x83 {
    return CBORRecord
  } else if b[0] >= 0xc0 && b[0] <= 0xdb {
    return CBORTag
  } else if b[0] == 0x5b {
    return JSONRecord
  } else if b[0] == 0x7b {
    return JSONCollection
  } else if (b[0] >= 0xa0 && b[0] <= 0xbb) || b[0] == 0xbf {
    return CBORCollection
  }

  return Unknown
}
~~~

# Transporting CMW in COSE and JOSE Web Tokens

To allow embedding CMWs and CMW collections into CBOR-based protocols and web APIs, this document defines two `"cmw"` claims for JSON Web Tokens (JWT) and CBOR Web Tokens (CWT).

Their definitions are provided in {{iana-jwt}} and {{iana-cwt}} respectively.

## Encoding Requirements

A CMW collection carried in a `"cmw"` JWT claim MUST be a `json-collection`.
A CMW collection carried in a `"cmw"` CWT claim MUST be a `cbor-collection`.

A CMW record carried in a `"cmw"` JWT claim MUST be a `json-record`.
A CMW record carried in a `"cmw"` CWT claim MUST be a `cbor-record`.

# Transporting CMW in X.509 Messages {#x509}

CMW may need to be transported in PKIX messages, such as Certificate Signing Requests (CSRs) or in X.509 Certificates and Certificate Revocation Lists (CRLs).
The former use is documented in {{-csr-a}}, the latter in Section 6.1 of {{DICE-arch}}.

This section specifies the CMW extension to carry CMW objects.

The CMW extension MAY be included in X.509 Certificates, CRLs {{-pkix}}, and CSRs.

The CMW extension MUST be identified by the following object identifier:

~~~asn.1
id-pe-cmw  OBJECT IDENTIFIER ::=
        { iso(1) identified-organization(3) dod(6) internet(1)
          security(5) mechanisms(5) pkix(7) id-pe(1) TBD }
~~~

This extension SHOULD NOT be marked critical.
It MAY be marked critical in cases where the attestation-related information is essential for granting resource access, and there is a risk that legacy relying parties would bypass such controls.

The CMW extension MUST have the following syntax:

~~~asn.1
CMW ::= CHOICE {
    json UTF8String,
    cbor OCTET STRING
}
~~~

The CMW MUST contain the serialized CMW object in JSON or CBOR format, using the appropriate CHOICE entry.

The DER-encoded CMW is the value of the OCTET STRING for the extnValue field of the extension.

## ASN.1 Module {#asn1-x509}

This section provides an ASN.1 module {{X.680}} for the CMW extension, following the conventions established in {{RFC5912}} and {{RFC6268}}.

~~~asn.1
CMWExtn
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

-- CMW Extension

ext-CMW EXTENSION ::= {
  SYNTAX CMW
  IDENTIFIED BY id-pe-cmw }

-- CMW Extension OID

id-pe-cmw  OBJECT IDENTIFIER  ::=
   { iso(1) identified-organization(3) dod(6) internet(1)
     security(5) mechanisms(5) pkix(7) id-pe(1) TBD }

-- CMW Extension Syntax

CMW ::= CHOICE {
    json UTF8String,
    cbor OCTET STRING
}

END
~~~

## Compatibility with DICE `ConceptualMessageWrapper`

Section 6.1.8 of {{DICE-arch}} defines the ConceptualMessageWrapper format and the associated object identifier.
The CMW format defined in {{DICE-arch}} allows only a subset of the CMW grammar defined in this document.
Specifically, the tunnel and collection formats cannot be encoded using DICE CMWs.

# Examples

The (equivalent) examples in {{ex-ja}}, {{ex-ca}}, and {{ex-ct}} assume that
the Media-Type-Name `application/vnd.example.rats-conceptual-msg` has been
registered alongside a corresponding CoAP Content-Format number `30001`.  The
CBOR tag `1668576818` is derived applying the `TN()` transform as described in
{{cbor-tag}}.

The example in {{ex-ca-ind}} is a signed CoRIM (Concise Reference Integrity Manifest) {{-rats-corim}} payload with an explicit CM
indicator `0b0000_0011` (3), meaning that the wrapped message contains both
Reference Values and Endorsements.

## JSON Record {#ex-ja}

~~~ cbor-diag
{::include cddl/cmw-example-1.json}
~~~

Note that a CoAP Content-Format number can also be used with the JSON record
form.  That may be the case when it is known that the receiver can handle CoAP
Content-Formats and it is crucial to save bytes.

## CBOR Record {#ex-ca}

~~~ cbor-diag
{::include cddl/cmw-example-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/cmw-example-1.pretty}
~~~

Note that a Media-Type-Name can also be used with the CBOR record form,
for example if it is known that the receiver cannot handle CoAP
Content-Formats, or (unlike the case in point) if a CoAP Content-Format
number has not been registrered.

~~~ cbor-diag
{::include cddl/cmw-example-2.diag}
~~~

## CBOR Tag {#ex-ct}

~~~ cbor-diag
{::include cddl/cmw-example-tag-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/cmw-example-tag-1.pretty}
~~~

## CBOR Record with explicit CM indicator {#ex-ca-ind}

~~~ cbor-diag
{::include cddl/cmw-example-3.diag}
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

The following example is a CBOR collection that assembles conceptual messages from three attesters: Evidence for attesters A and B and Attestation Results for attester C.
It is given an explicit collection type using the URI form.

~~~
{::include cddl/collection-example-1.diag}
~~~

with the following wire representation:

~~~
{::include cddl/collection-example-1.pretty}
~~~

The following example shows the use of a tunnelled type to move a JSON record to a CBOR collection:

~~~
{::include cddl/collection-example-2.diag}
~~~

## JSON Collection

The following example is a JSON collection that assembles Evidence from two attesters.

~~~
{::include cddl/collection-example-1.json}
~~~

The following example shows the use of a tunnelled type to move a CBOR record to a JSON collection:

~~~
{::include cddl/collection-example-2.json}
~~~

## Use in JWT

The following example shows the use of the `"cmw"` JWT claim to transport a CMW collection in a JWT {{-jwt}}:

~~~
{::include cddl/eat-example-1.json}
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

## Records and CBOR Tags

RATS conceptual messages are typically secured using cryptography.
If the messages are already protected, then there are no additional security requirements imposed by the introduction of this encapsulation.
If an adversary tries to modify the payload encapsulation, it will result in incorrect processing of the encapsulated message and lead to an error.
If the messages are not protected, additional security must be added at a different layer.
As an example, a `cbor-record` containing an UCCS (Unprotected CWT Claims Sets) {{-rats-uccs}} can be signed using COSE Sign1 {{-cose}}.

## Collections {#seccons-coll}

If the collection is not protected from tampering by external security measures (such as object security primitives) or internal mechanisms (such as intra-item binding), an attacker could easily manipulate the collection's contents.
It is the responsibility of the Attester who creates the CMW collection to ensure that the contents of the collection are integrity-protected.
The designer of the attestation technology is typically in charge of ensuring that the security properties are met, not the user of the conceptual message wrapper.
In particular, when a CMW is used to carry multiple Evidence messages for a composite device or layered attestation, there should be strong binding between the Evidence messages within the collection.
This binding is needed to prevent attacks where Evidence from a subverted part of the device is replaced by Evidence from a separate non-subverted device.
The binding of Evidence messages should be some form of attestation.
For example, key material used to sign/bind an entire CMW collection should be an attestation key, handled as described in {{Section 12.1 of -rats-arch}}.
The binding does not necessarily have to be a signature over the CMW collection, it might also be achieved through identifiers, cross-linking, signing or hashing between the members of the collection.
Client-authenticated TLS may be used to bind a CMW collection of Evidence messages.
However, the client key used with TLS should not be that of the end-user or owner of the device.
Instead, it should be attestation-oriented key material from the device or the attester manufacturer.

# IANA Considerations

[^rfced] replace "{{&SELF}}" with the RFC number assigned to this document.

## CWT `cmw` Claim Registration {#iana-cwt}

IANA is requested to add a new `cmw` claim to the "CBOR Web Token (CWT) Claims" registry {{IANA.cwt}} as follows:

* Claim Name: cmw
* Claim Description: A RATS Conceptual Message Wrapper
* Claim Key: TBD
* Claim Value Type(s): CBOR Map, CBOR Array, or CBOR Tag
* Change Controller: IETF
* Specification Document(s): {{type-n-val}}, {{cmw-coll}} and {{cbor-tag}} of {{&SELF}}

The suggested value for the Claim Key is 299.

## JWT `cmw` Claim Registration {#iana-jwt}

IANA is requested to add a new `cmw` claim to the "JSON Web Token Claims" sub-registry of the "JSON Web Token (JWT)" registry {{IANA.jwt}} as follows:

* Claim Name: cmw
* Claim Description: A RATS Conceptual Message Wrapper
* Change Controller: IETF
* Specification Document(s): {{type-n-val}} and {{cmw-coll}} of {{&SELF}}

## CBOR Tag Registration

IANA is requested to add the following tag to the "CBOR Tags" {{!IANA.cbor-tags}} registry.

| CBOR Tag | Data Item | Semantics | Reference |
|----------|-----------|-----------|-----------|
| TBD      | CBOR map, CBOR array, CBOR tag | RATS Conceptual Message Wrapper | {{type-n-val}}, {{cbor-tag}} and {{cmw-coll}} of {{&SELF}} |

## RATS Conceptual Message Wrapper (CMW) Indicators Registry {#iana-ind-ext}

This specification defines a new "RATS Conceptual Message Wrapper (CMW) Indicators" registry, with the policy "Expert Review" ({{Section 4.5 of -ianacons}}).

The objective is to have CMW Indicators values registered for all RATS Conceptual Messages ({{Section 8 of -rats-arch}}).

### Instructions for the Designated Expert {#de-instructions}

The expert is instructed to add the values incrementally.

Acceptable values are those corresponding to RATS Conceptual Messages defined by the RATS architecture {{-rats-arch}} and any of its updates.

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
| 0 | Reference Values | {{&SELF}} |
| 1 | Endorsements | {{&SELF}} |
| 2 | Evidence | {{&SELF}} |
| 3 | Attestation Results | {{&SELF}} |
| 4-31 | Unassigned | {{&SELF}} |
{: #tab-ind-regs title="CMW Indicators Registry Initial Contents"}

### Provisional Registration

Before the creation of the registry by IANA, new codepoints can be added to the [provisional CMW Indicators registry](https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/blob/main/provisional/cmw-indicators-registry.md) by following the documented procedure.

{{tab-ind-regs}} will be regularly updated to match the contents of the provisional registry.

The provisional registry will be discontinued once IANA establishes the permanent registry, which is expected to coincide with the publication of the current document.

## Media Types

IANA is requested to add the following media types to the "Media Types" registry {{!IANA.media-types}}.

| Name | Template | Reference |
|-----------------|-------------------------|-----------|
| `cmw+cbor` | `application/cmw+cbor` | {{type-n-val}}, {{cbor-tag}} and {{cmw-coll}} of {{&SELF}} |
| `cmw+json` | `application/cmw+json` | {{type-n-val}} and {{cmw-coll}} of {{&SELF}} |
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
: `cmwc_t` (CMW collection type in string format.  The parameter value is case-insensitive.  It MUST NOT be used for CMW that are not collections.)

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
: `cmwc_t` (CMW collection type in string format.  The parameter value is case-insensitive.  It MUST NOT be used for CMW that are not collections.)

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

## CoAP Content Formats

IANA is requested to register the following Content-Format numbers in the "CoAP Content-Formats" sub-registry, within the "Constrained RESTful Environments (CoRE) Parameters" Registry {{!IANA.core-parameters}}:

| Content-Type | Content Coding | ID | Reference |
| application/cmw+cbor | - | TBD1 | {{type-n-val}}, {{cbor-tag}} and {{cmw-coll}} of {{&SELF}} |
| application/cmw+json | - | TBD2 | {{type-n-val}} and {{cmw-coll}} of {{&SELF}} |
{: align="left" title="New CoAP Content Formats"}

If possible, TBD1 and TBD2 should be assigned in the 256..999 range.

## New SMI Numbers Registrations

IANA is requested to assign an object identifier (OID) for the CMW extension defined in {{x509}} in the "Certificate Extension" sub-registry of the "SMI Numbers" {{!IANA.smi-numbers}} registry.

IANA is requested to assign an object identifier (OID) for the ASN.1 Module defined in {{asn1-x509}} in the "Module Identifier" sub-registry of the "SMI Numbers" {{!IANA.smi-numbers}} registry.

--- back

## Collected CDDL {#collected-cddl}

~~~ cddl
{::include cddl/collected-cddl-autogen.cddl}
~~~

# Registering and Using CMWs

{{fig-howto-cmw}} describes the registration preconditions for using
CMWs in either CMW record or CBOR tag forms.
When using CMW collection, the preconditions apply for each entry in the collection.

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
   /                 CMW                  /
  `--------------------------------------'
~~~
{: #fig-howto-cmw artwork-align="left"
   title="How To Create a CMW"}

# Open Issues

The list of currently open issues for this documents can be found at
[](https://github.com/thomas-fossati/draft-ftbs-rats-msg-wrap/issues).

<cref>Note to RFC Editor: please remove before publication.</cref>

# Acknowledgments
{:numbered="false"}

The authors would like to thank
Brian Campbell,
Carl Wallace,
Carsten Bormann,
Dionna Glaze,
{{{Ionuț Mihalcea}}}
Laurence Lundblade,
Michael B. Jones,
Mohit Sethi,
Russ Housley,
and
Tom Jones
for their reviews and suggestions.

The definition of a CMW collection has been modelled on a proposal originally made by Simon Frost for an EAT-based Evidence collection type.  The CMW collection intentionally attains binary compatibility with Simon's design and aims at superseding it by also generalizing on the allowed Evidence formats.

[^note]: Note:
[^issue]: Open issue:
[^rfced]: RFC Editor:
