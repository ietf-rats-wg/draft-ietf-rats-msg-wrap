.DEFAULT_GOAL := check

SHELL := /bin/bash

%.cbor: %.diag ; diag2cbor.rb $< > $@

# leave cmw-cbor-tag out for now as it needs CDDL 2.0
CDDL_FRAG := cmw-array.cddl
CDDL_FRAG += rfc9193.cddl
CDDL_FRAG += jc.cddl

CDDL_FILE := cmw.cddl

DIAG_FILES := $(wildcard example*.diag)

CBOR_FILES := $(DIAG_FILES:.diag=.cbor)
PRETTY_FILES := $(CBOR_FILES:.cbor=.pretty)

CLEANFILES += $(CBOR_FILES)
CLEANFILES += $(PRETTY_FILES)

XXX_SKIP_CBOR_TAG_FILE := example-cbor-tag-1.cbor

$(CDDL_FILE): $(CDDL_FRAG)
	for f in $(CDDL_FRAG) ; do cat $$f >> $@ ; done

CLEANFILES += $(CDDL_FILE)

check: $(CDDL_FILE) $(CBOR_FILES)
	@for f in $(CBOR_FILES) ; do \
		echo ">> prettyfying $$f" ; \
		cbor2pretty.rb $$f > $${f%.cbor}.pretty ; \
		[ $$f == $(XXX_SKIP_CBOR_TAG_FILE) ] && continue ; \
		echo ">> validating $$f" ; \
		cddl $(CDDL_FILE) validate $$f || exit 1; \
	done

clean: ; rm -f $(CLEANFILES)
