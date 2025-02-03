LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update --init
else
ifneq (,$(wildcard $(ID_TEMPLATE_HOME)))
	ln -s "$(ID_TEMPLATE_HOME)" $(LIBDIR)
else
	git clone -q --depth 10 -b main \
	    https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
endif

include cddl/frags.mk

EXAMPLES_JSON := $(addprefix cddl/,$(CMW_JSON_EXAMPLES))
EXAMPLES_JSON += $(addprefix cddl/,$(EAT_JSON_EXAMPLES))

EXAMPLES_DIAG := $(addprefix cddl/,$(CMW_CBOR_EXAMPLES))
EXAMPLES_DIAG += $(addprefix cddl/,$(EAT_CBOR_EXAMPLES))

EXAMPLES_PRETTY := $(EXAMPLES_DIAG:.diag=.pretty)

CDDL_FILES := $(addprefix cddl/,$(CMW_FRAGS))
CDDL_FILES += $(addprefix cddl/,$(EAT_FRAGS))

$(drafts_txt):: $(EXAMPLES_DIAG) $(EXAMPLES_JSON) $(EXAMPLES_PRETTY) $(CDDL_FILES)

$(EXAMPLES_PRETTY): $(EXAMPLES_DIAG)
	$(MAKE) -C cddl

clean::
	$(MAKE) -C cddl clean
