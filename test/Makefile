# -------- test/Makefile --------
ROOT       := ..
BUILD_DIR  := $(ROOT)/build
BIN_DIR    := $(ROOT)/bin
LIB        ?= $(BIN_DIR)/libsdcc-z80.lib

# Normalize LIB if it was passed like "bin/xxx.lib" from repo root
ifeq (,$(filter /% ../% ./%,$(LIB)))
  LIB := $(ROOT)/$(LIB)
endif

# Tools & flags (force SDCC tools; avoid host 'as')
override CC := sdcc
override AS := sdasz80
override AR := sdar

CFLAGS  = --std-c11 -mz80 -I. --no-std-crt0 --nostdinc --nostdlib --debug
ASFLAGS = -x -g
ENVPATH := env PATH=/opt/sdcc/bin:$$PATH

# Minimal startup in test/
CRT0_SRC   := crt0_min.s
CRT0_OBJ   := $(BUILD_DIR)/crt0_min.rel

# All C tests in this folder
TEST_SRCS  := $(wildcard *.c)
TEST_BASEN := $(basename $(notdir $(TEST_SRCS)))
TEST_IHX   := $(addprefix $(BUILD_DIR)/,$(addsuffix .ihx,$(TEST_BASEN)))

.PHONY: all clean print
all: $(BUILD_DIR) $(CRT0_OBJ) $(TEST_IHX)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Assemble crt0 to ../build (explicit output path)
$(CRT0_OBJ): $(CRT0_SRC) | $(BUILD_DIR)
	@echo "[as] $< -> $@"
	@$(ENVPATH) $(AS) $(ASFLAGS) -o $@ $(abspath $<)

# ---- concrete rules per test ----
define TEST_template
$(BUILD_DIR)/$(1).rel: $(1).c | $(BUILD_DIR)
	@echo "[cc] $(1).c -> $$@"
	@$(ENVPATH) $(CC) $(CFLAGS) -c -o $$@ $$<

$(BUILD_DIR)/$(1).ihx: $(BUILD_DIR)/$(1).rel $(CRT0_OBJ) $(LIB) | $(BUILD_DIR)
	@echo "[link] $(1).ihx"
	@$(ENVPATH) $(CC) -mz80 --no-std-crt0 --nostdlib --nostdinc \
	    $(CRT0_OBJ) $(BUILD_DIR)/$(1).rel $(LIB) -o $$@
endef
$(foreach T,$(TEST_BASEN),$(eval $(call TEST_template,$(T))))

clean:
	@echo "[test/clean] removing test artifacts from $(BUILD_DIR)"
	@rm -f $(BUILD_DIR)/*.rel $(BUILD_DIR)/*.ihx

print:
	@echo "LIB        = $(LIB)"
	@echo "BUILD_DIR  = $(BUILD_DIR)"
	@echo "TEST_SRCS  = $(TEST_SRCS)"
	@echo "TESTS      = $(TEST_BASEN)"
