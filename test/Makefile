# -------- test/Makefile --------

# Paths
ROOT        := ..
BUILD_DIR   := $(ROOT)/build/tests
BIN_DIR     := $(ROOT)/bin
LIB         := $(BIN_DIR)/libsdcc-z80.lib

# Tools & flags (inherited from environment or top-level make)
CC          ?= sdcc
CFLAGS      ?= --std-c11 -mz80 -I. --no-std-crt0 --nostdinc --nostdlib --debug
AS          ?= sdasz80
ASFLAGS     ?= -xlos -g

# All test sources
TEST_SRCS   := $(wildcard *.c)
TEST_BASEN  := $(basename $(notdir $(TEST_SRCS)))

# Each test becomes a .ihx in BUILD_DIR
TESTS       := $(addprefix $(BUILD_DIR)/,$(addsuffix .ihx,$(TEST_BASEN)))

# Minimal startup
CRT0        := crt0_min.s
CRT0_REL    := $(BUILD_DIR)/crt0_min.rel

.PHONY: all clean

all: $(TESTS)

# Rule: test.c -> .ihx
$(BUILD_DIR)/%.ihx: %.c $(CRT0_REL) $(LIB) | $(BUILD_DIR)
	@echo "[test] linking $< -> $@"
	$(CC) -mz80 --no-std-crt0 --nostdlib --nostdinc \
	    $(CRT0_REL) $(BUILD_DIR)/$*.rel $(LIB) -o $@

# Compile C test into .rel
$(BUILD_DIR)/%.rel: %.c | $(BUILD_DIR)
	@echo "[cc] $<"
	$(CC) $(CFLAGS) -c -o $@ $<

# Assemble minimal crt0
$(CRT0_REL): $(CRT0) | $(BUILD_DIR)
	@echo "[as] $<"
	cd $(BUILD_DIR) && $(AS) $(ASFLAGS) $(abspath $<)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

clean:
	@echo "[clean] removing test build dir"
	@rm -rf $(BUILD_DIR)
