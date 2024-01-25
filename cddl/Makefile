.DEFAULT_GOAL := check

SHELL := /bin/bash

%.cbor: %.diag ; diag2cbor.rb $< > $@

CDDL_FRAG := cmw-start.cddl
CDDL_FRAG += cmw-array.cddl
CDDL_FRAG += cmw-cbor-tag.cddl
CDDL_FRAG += cmw-collection.cddl
CDDL_FRAG += rfc9193.cddl
CDDL_FRAG += jc.cddl

CDDL_FILE := cmw.cddl

DIAG_FILES := $(wildcard example*.diag)

CBOR_FILES := $(DIAG_FILES:.diag=.cbor)
PRETTY_FILES := $(CBOR_FILES:.cbor=.pretty)

CLEANFILES += $(CBOR_FILES)
CLEANFILES += $(PRETTY_FILES)

$(CDDL_FILE): $(CDDL_FRAG)
	rm -f $@
	for f in $(CDDL_FRAG) ; do cat $$f >> $@ ; echo >> $@ ; done

CLEANFILES += $(CDDL_FILE)

check: $(CDDL_FILE) $(CBOR_FILES)
	@for f in $(CBOR_FILES) ; do \
		echo ">> prettyfying $$f" ; \
		cbor2pretty.rb $$f > $${f%.cbor}.pretty ; \
		echo ">> validating $$f" ; \
		cddl $(CDDL_FILE) validate $$f || exit 1; \
	done

clean: ; rm -f $(CLEANFILES)
