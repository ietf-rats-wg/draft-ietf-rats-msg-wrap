.DEFAULT_GOAL := check

SHELL := /bin/bash

include cddl-check-template.mk
include frags.mk

check:: check-cmw check-cmw-examples
check:: check-collection check-collection-examples

$(eval $(call cddl_check_template,cmw,$(CMW_FRAGS),$(CMW_EXAMPLES)))
$(eval $(call cddl_check_template,collection,$(COLLECTION_FRAGS),$(COLLECTION_EXAMPLES)))

clean: ; rm -f $(CLEANFILES)
