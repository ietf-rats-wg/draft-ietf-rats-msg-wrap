LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

include cddl/frags.mk

EXAMPLES_DIAG := $(addprefix cddl/,$(CMW_EXAMPLES))
EXAMPLES_DIAG += $(addprefix cddl/,$(COLLECTION_EXAMPLES))

EXAMPLES_PRETTY := $(EXAMPLES_DIAG:.diag=.pretty)

CDDL_FILES := $(addprefix cddl/,$(CMW_FRAGS))
CDDL_FILES += $(addprefix cddl/,$(COLLECTION_FRAGS))

$(drafts_txt):: $(EXAMPLES_DIAG) $(EXAMPLES_PRETTY) $(CDDL_FILES)

$(EXAMPLES_PRETTY): $(EXAMPLES_DIAG)
	$(MAKE) -C cddl

clean::
	$(MAKE) -C cddl clean
