# -------- test/src/compile/Makefile (c-only, link each test separately) --------

ROOT := $(abspath $(CURDIR)/../../..)
SRC_DIR := .

# Allow injection from the command line:
#   make BUILD_DIR=... BIN_DIR=...
# BUILD_DIR is the repo-level build directory; this Makefile uses BUILD_DIR/test/compile.
BUILD_DIR ?= $(ROOT)/build
BIN_DIR   ?= $(ROOT)/bin

# Normalize BUILD_DIR/BIN_DIR.
# If relative, interpret relative to repo root so it stays stable regardless of -C depth.
ifneq ($(filter /%,$(BUILD_DIR)),)
BUILD_DIR := $(abspath $(BUILD_DIR))
else
BUILD_DIR := $(abspath $(ROOT)/$(BUILD_DIR))
endif

ifneq ($(filter /%,$(BIN_DIR)),)
BIN_DIR := $(abspath $(BIN_DIR))
else
BIN_DIR := $(abspath $(ROOT)/$(BIN_DIR))
endif

COMPILE_BUILD_DIR := $(BUILD_DIR)/test/compile

CC := sdcc
LD := sdldz80

CFLAGS := --std-c11 -mz80 --debug \
          --no-std-crt0 --nostdinc --nostdlib \
          -I. -I$(ROOT)/test/include

# Runtime helper coverage test needs large model/banked code paths enabled.
RUNTIME_TEST := test_runtime
RUNTIME_CFLAGS := --model-large --opt-code-size

LIB_MAIN := $(BIN_DIR)/libsdcc-z80.lib

C_SRCS := $(wildcard $(SRC_DIR)/*.c)
TESTS  := $(basename $(notdir $(C_SRCS)))

IHXS := $(addprefix $(COMPILE_BUILD_DIR)/,$(addsuffix .ihx,$(TESTS)))

.PHONY: all clean lib-main
all: lib-main $(IHXS)

# Always rebuild the main runtime library before compile-link checks so
# newly added helper objects/symbols are present.
lib-main:
	$(MAKE) -C "$(ROOT)/src" BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

# Compile each test file
$(COMPILE_BUILD_DIR)/%.rel: $(SRC_DIR)/%.c
	mkdir -p "$(dir $@)"
	$(CC) $(CFLAGS) $(if $(filter $(RUNTIME_TEST),$*),$(RUNTIME_CFLAGS),) -c -o "$(abspath $@)" "$<"

# Link each test separately to validate symbols (no tap/bin needed)
$(COMPILE_BUILD_DIR)/%.ihx: $(COMPILE_BUILD_DIR)/%.rel $(LIB_MAIN)
	mkdir -p "$(COMPILE_BUILD_DIR)"
	{ \
	  echo "-i"; \
	  echo "-m"; \
	  echo "-j"; \
	  echo "-o $(abspath $@)"; \
	  echo "$(abspath $(COMPILE_BUILD_DIR)/$*.rel)"; \
	  echo "$(abspath $(LIB_MAIN))"; \
	} > "$(abspath $(COMPILE_BUILD_DIR)/$*.lk)"
	$(LD) -f "$(abspath $(COMPILE_BUILD_DIR)/$*.lk)"

clean:
	rm -rf "$(COMPILE_BUILD_DIR)"
