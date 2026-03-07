# -------- test/src/execute/Makefile (c-only, two ZX Spectrum TAPs) --------

# -------- test/src/execute/Makefile --------
# Builds both ZX Spectrum .TAP files and CP/M .COM files from the same sources.

ROOT := $(abspath $(CURDIR)/../../..)
SRC_DIR := .

# Injected by parent makefiles. If relative, treat as repo-root relative.
BUILD_DIR ?= $(ROOT)/build
BIN_DIR   ?= $(ROOT)/bin

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

EXEC_BUILD_DIR := $(BUILD_DIR)/test/execute

CC      := sdcc
LD      := sdldz80
OBJCOPY := sdobjcopy
BIN2TAP := bin2tap

CFLAGS := --std-c11 -mz80 --debug \
          --no-std-crt0 --nostdinc --nostdlib \
          -I. -I$(ROOT)/test/include

# ---------- ZX Spectrum targets ----------
ZX_LOAD_HEX ?= 0x8000
ZX_LOAD_DEC ?= 32768

CRT0_ZX  := $(BIN_DIR)/crt0zx.rel
LIB_MAIN := $(BIN_DIR)/libsdcc-z80.lib
LIB_ZX   := $(BIN_DIR)/libzx.lib

ITAP := $(BIN_DIR)/itestzx.tap
FTAP := $(BIN_DIR)/ftestzx.tap

INT_C_SRCS   := $(wildcard $(SRC_DIR)/int/*.c)
FLOAT_C_SRCS := $(wildcard $(SRC_DIR)/float/*.c)

INT_C_OBJS_ZX   := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/zx/%.rel,$(INT_C_SRCS)))
FLOAT_C_OBJS_ZX := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/zx/%.rel,$(FLOAT_C_SRCS)))

IHX_INT_ZX  := $(EXEC_BUILD_DIR)/zx/int/itestzx.ihx
BIN_INT_ZX  := $(EXEC_BUILD_DIR)/zx/int/itestzx.bin
LK_INT_ZX   := $(EXEC_BUILD_DIR)/zx/int/itestzx.lk

IHX_FLOAT_ZX := $(EXEC_BUILD_DIR)/zx/float/ftestzx.ihx
BIN_FLOAT_ZX := $(EXEC_BUILD_DIR)/zx/float/ftestzx.bin
LK_FLOAT_ZX  := $(EXEC_BUILD_DIR)/zx/float/ftestzx.lk

# ---------- CP/M targets ----------
CPM_LOAD_HEX ?= 0x0100

CRT0_CPM := $(BIN_DIR)/crt0cpm.rel
LIB_CPM  := $(BIN_DIR)/libcpm.lib

ICOM := $(BIN_DIR)/itest.com
FCOM := $(BIN_DIR)/ftest.com

INT_C_OBJS_CPM   := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/cpm/%.rel,$(INT_C_SRCS)))
FLOAT_C_OBJS_CPM := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/cpm/%.rel,$(FLOAT_C_SRCS)))

IHX_INT_CPM  := $(EXEC_BUILD_DIR)/cpm/int/itest.ihx
LK_INT_CPM   := $(EXEC_BUILD_DIR)/cpm/int/itest.lk

IHX_FLOAT_CPM := $(EXEC_BUILD_DIR)/cpm/float/ftest.ihx
LK_FLOAT_CPM  := $(EXEC_BUILD_DIR)/cpm/float/ftest.lk

# ---------- phony targets ----------
.PHONY: all clean zx cpm

all: zx cpm

zx: $(ITAP) $(FTAP)

cpm: $(ICOM) $(FCOM)

# ==========================================================================
# ZX Spectrum build
# ==========================================================================

$(IHX_INT_ZX): $(CRT0_ZX) $(INT_C_OBJS_ZX) $(LIB_MAIN) $(LIB_ZX)
	mkdir -p "$(dir $@)"
	{ \
	  echo "-b_CODE=$(ZX_LOAD_HEX)"; \
	  echo "-i"; echo "-m"; echo "-j"; \
	  echo "-o $(abspath $(IHX_INT_ZX))"; \
	  echo "$(abspath $(CRT0_ZX))"; \
	  for obj in $(INT_C_OBJS_ZX); do echo "$$obj"; done; \
	  echo "$(abspath $(LIB_MAIN))"; \
	  echo "$(abspath $(LIB_ZX))"; \
	} > "$(LK_INT_ZX)"
	$(LD) -f "$(LK_INT_ZX)"

$(IHX_FLOAT_ZX): $(CRT0_ZX) $(FLOAT_C_OBJS_ZX) $(LIB_MAIN) $(LIB_ZX)
	mkdir -p "$(dir $@)"
	{ \
	  echo "-b_CODE=$(ZX_LOAD_HEX)"; \
	  echo "-i"; echo "-m"; echo "-j"; \
	  echo "-o $(abspath $(IHX_FLOAT_ZX))"; \
	  echo "$(abspath $(CRT0_ZX))"; \
	  for obj in $(FLOAT_C_OBJS_ZX); do echo "$$obj"; done; \
	  echo "$(abspath $(LIB_MAIN))"; \
	  echo "$(abspath $(LIB_ZX))"; \
	} > "$(LK_FLOAT_ZX)"
	$(LD) -f "$(LK_FLOAT_ZX)"

$(BIN_INT_ZX): $(IHX_INT_ZX)
	$(OBJCOPY) -I ihex -O binary "$(IHX_INT_ZX)" "$(BIN_INT_ZX)"

$(BIN_FLOAT_ZX): $(IHX_FLOAT_ZX)
	$(OBJCOPY) -I ihex -O binary "$(IHX_FLOAT_ZX)" "$(BIN_FLOAT_ZX)"

$(ITAP): $(BIN_INT_ZX)
	mkdir -p "$(BIN_DIR)"
	$(BIN2TAP) -b -o "$@" -a $(ZX_LOAD_DEC) "$(BIN_INT_ZX)"

$(FTAP): $(BIN_FLOAT_ZX)
	mkdir -p "$(BIN_DIR)"
	$(BIN2TAP) -b -o "$@" -a $(ZX_LOAD_DEC) "$(BIN_FLOAT_ZX)"

$(EXEC_BUILD_DIR)/zx/%.rel: $(SRC_DIR)/%.c
	mkdir -p "$(dir $@)"
	$(CC) $(CFLAGS) -c -o "$(abspath $@)" "$<"

# ==========================================================================
# CP/M build
# ==========================================================================

$(IHX_INT_CPM): $(CRT0_CPM) $(INT_C_OBJS_CPM) $(LIB_MAIN) $(LIB_CPM)
	mkdir -p "$(dir $@)"
	{ \
	  echo "-b_CODE=$(CPM_LOAD_HEX)"; \
	  echo "-i"; echo "-m"; echo "-j"; \
	  echo "-o $(abspath $(IHX_INT_CPM))"; \
	  echo "$(abspath $(CRT0_CPM))"; \
	  for obj in $(INT_C_OBJS_CPM); do echo "$$obj"; done; \
	  echo "$(abspath $(LIB_MAIN))"; \
	  echo "$(abspath $(LIB_CPM))"; \
	} > "$(LK_INT_CPM)"
	$(LD) -f "$(LK_INT_CPM)"

$(IHX_FLOAT_CPM): $(CRT0_CPM) $(FLOAT_C_OBJS_CPM) $(LIB_MAIN) $(LIB_CPM)
	mkdir -p "$(dir $@)"
	{ \
	  echo "-b_CODE=$(CPM_LOAD_HEX)"; \
	  echo "-i"; echo "-m"; echo "-j"; \
	  echo "-o $(abspath $(IHX_FLOAT_CPM))"; \
	  echo "$(abspath $(CRT0_CPM))"; \
	  for obj in $(FLOAT_C_OBJS_CPM); do echo "$$obj"; done; \
	  echo "$(abspath $(LIB_MAIN))"; \
	  echo "$(abspath $(LIB_CPM))"; \
	} > "$(LK_FLOAT_CPM)"
	$(LD) -f "$(LK_FLOAT_CPM)"

# sdobjcopy emits a flat binary starting at the first IHX record address
# (0x0100 for CP/M), producing a valid .COM file with no leading padding.
$(ICOM): $(IHX_INT_CPM) | $(BIN_DIR)
	$(OBJCOPY) -I ihex -O binary "$(IHX_INT_CPM)" "$@"

$(FCOM): $(IHX_FLOAT_CPM) | $(BIN_DIR)
	$(OBJCOPY) -I ihex -O binary "$(IHX_FLOAT_CPM)" "$@"

$(EXEC_BUILD_DIR)/cpm/%.rel: $(SRC_DIR)/%.c
	mkdir -p "$(dir $@)"
	$(CC) $(CFLAGS) -c -o "$(abspath $@)" "$<"

$(BIN_DIR):
	mkdir -p "$(BIN_DIR)"

# ==========================================================================
# Clean
# ==========================================================================
clean:
	rm -rf "$(EXEC_BUILD_DIR)"
	rm -f "$(ITAP)" "$(FTAP)" "$(ICOM)" "$(FCOM)"
