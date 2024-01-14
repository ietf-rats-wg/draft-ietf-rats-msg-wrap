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

EXAMPLES_DIAG := $(wildcard cddl/example*.diag)
EXAMPLES_PRETTY := $(EXAMPLES_DIAG:.diag=.pretty)
CDDL_FILES := cddl/cmw-array.cddl
CDDL_FILES += cddl/cmw-cbor-tag.cddl
CDDL_FILES += cddl/cmw-start.cddl
CDDL_FILES += cddl/cmw-collection.cddl

$(drafts_txt):: $(EXAMPLES_DIAG) $(EXAMPLES_PRETTY) $(CDDL_FILES)

$(EXAMPLES_PRETTY): $(EXAMPLES_DIAG)
	$(MAKE) -C cddl

clean::
	$(MAKE) -C cddl clean
