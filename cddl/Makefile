.DEFAULT_GOAL := check

SHELL := /bin/bash

include cddl-check-template.mk
include frags.mk

check:: check-cmw check-cmw-examples
check:: check-eat check-eat-examples
check:: check-collected-cddl check-signed-cbor-cmw check-signed-json-cmw

$(eval $(call cddl_check_template,cmw,$(CMW_FRAGS),$(CMW_CBOR_EXAMPLES),$(CMW_JSON_EXAMPLES)))
$(eval $(call cddl_check_template,eat,$(EAT_FRAGS),$(EAT_CBOR_EXAMPLES),$(EAT_JSON_EXAMPLES)))
$(eval $(call cddl_check_template,collected-cddl,$(COLLECTED_CDDL_FRAGS),$(unused),$(unused)))
$(eval $(call cddl_check_template,signed-cbor-cmw,$(SIGNED_CBOR_CMW_CDDL_FRAGS),$(unused),$(unused)))
$(eval $(call cddl_check_template,signed-json-cmw,$(SIGNED_JSON_CMW_CDDL_FRAGS),$(unused),$(unused)))

clean: ; rm -f $(CLEANFILES)
