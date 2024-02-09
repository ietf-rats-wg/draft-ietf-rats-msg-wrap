.DEFAULT_GOAL := check

SHELL := /bin/bash

include cddl-check-template.mk
include frags.mk

check:: check-cmw check-cmw-examples

$(eval $(call cddl_check_template,cmw,$(CMW_FRAGS),$(CMW_CBOR_EXAMPLES),$(CMW_JSON_EXAMPLES)))

clean: ; rm -f $(CLEANFILES)
