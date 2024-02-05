CMW_FRAGS := cmw-start.cddl
CMW_FRAGS += cmw.cddl
CMW_FRAGS += cmw-array.cddl
CMW_FRAGS += cmw-cbor-tag.cddl
CMW_FRAGS += rfc9193.cddl
CMW_FRAGS += jc.cddl

CMW_EXAMPLES := $(wildcard cmw-example-*.diag)

COLLECTION_FRAGS := cmw-collection-start.cddl
COLLECTION_FRAGS += cmw-collection.cddl
COLLECTION_FRAGS += cmw.cddl
COLLECTION_FRAGS += cmw-array.cddl
COLLECTION_FRAGS += cmw-cbor-tag.cddl
COLLECTION_FRAGS += rfc9193.cddl
COLLECTION_FRAGS += jc.cddl

COLLECTION_EXAMPLES := $(wildcard collection-example-*.diag)
