signed-cbor-cmw-headers.cddl: signed-cbor-cmw-headers.cddl.in ; sed -e 's/TBD1/10000/' $< > $@

CLEANFILES += signed-cbor-cmw-headers.cddl
