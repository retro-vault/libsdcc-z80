# -------- test/src/execute/Makefile (c-only, two ZX Spectrum TAPs) --------

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

LOAD_ADDR_HEX ?= 0x8000
LOAD_ADDR_DEC ?= 32768

CC      := sdcc
LD      := sdldz80
OBJCOPY := sdobjcopy
BIN2TAP := bin2tap

CFLAGS := --std-c11 -mz80 --debug \
          --no-std-crt0 --nostdinc --nostdlib \
          -I. -I$(ROOT)/test/include

CRT0_REL := $(BIN_DIR)/crt0zx.rel
LIB_MAIN := $(BIN_DIR)/libsdcc-z80.lib
LIB_ZX   := $(BIN_DIR)/libzx.lib

ITAP := $(BIN_DIR)/itestzx.tap
FTAP := $(BIN_DIR)/ftestzx.tap

.PHONY: all clean int float
all: $(ITAP) $(FTAP)

int: $(ITAP)
float: $(FTAP)

# Sources
INT_C_SRCS   := $(wildcard $(SRC_DIR)/int/*.c)
FLOAT_C_SRCS := $(wildcard $(SRC_DIR)/float/*.c)

# Objects (absolute; preserve subdirs under execute/)
INT_C_OBJS   := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/%.rel,$(INT_C_SRCS)))
FLOAT_C_OBJS := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/%.rel,$(FLOAT_C_SRCS)))

# Outputs
IHX_INT   := $(EXEC_BUILD_DIR)/int/itestzx.ihx
BIN_INT   := $(EXEC_BUILD_DIR)/int/itestzx.bin
LK_INT    := $(EXEC_BUILD_DIR)/int/itestzx.lk

IHX_FLOAT := $(EXEC_BUILD_DIR)/float/ftestzx.ihx
BIN_FLOAT := $(EXEC_BUILD_DIR)/float/ftestzx.bin
LK_FLOAT  := $(EXEC_BUILD_DIR)/float/ftestzx.lk

# --- link via generated .lk (ALL ABSOLUTE PATHS; no -l) ---
$(IHX_INT): $(CRT0_REL) $(INT_C_OBJS) $(LIB_MAIN) $(LIB_ZX)
	mkdir -p "$(dir $@)"
	{ \
	  echo "-b_CODE=$(LOAD_ADDR_HEX)"; \
	  echo "-i"; \
	  echo "-m"; \
	  echo "-j"; \
	  echo "-o $(abspath $(IHX_INT))"; \
	  echo "$(abspath $(CRT0_REL))"; \
	  for obj in $(INT_C_OBJS); do echo "$$obj"; done; \
	  echo "$(abspath $(LIB_MAIN))"; \
	  echo "$(abspath $(LIB_ZX))"; \
	} > "$(LK_INT)"
	$(LD) -f "$(LK_INT)"

$(IHX_FLOAT): $(CRT0_REL) $(FLOAT_C_OBJS) $(LIB_MAIN) $(LIB_ZX)
	mkdir -p "$(dir $@)"
	{ \
	  echo "-b_CODE=$(LOAD_ADDR_HEX)"; \
	  echo "-i"; \
	  echo "-m"; \
	  echo "-j"; \
	  echo "-o $(abspath $(IHX_FLOAT))"; \
	  echo "$(abspath $(CRT0_REL))"; \
	  for obj in $(FLOAT_C_OBJS); do echo "$$obj"; done; \
	  echo "$(abspath $(LIB_MAIN))"; \
	  echo "$(abspath $(LIB_ZX))"; \
	} > "$(LK_FLOAT)"
	$(LD) -f "$(LK_FLOAT)"

# --- ihx -> bin ---
$(BIN_INT): $(IHX_INT)
	$(OBJCOPY) -I ihex -O binary "$(IHX_INT)" "$(BIN_INT)"

$(BIN_FLOAT): $(IHX_FLOAT)
	$(OBJCOPY) -I ihex -O binary "$(IHX_FLOAT)" "$(BIN_FLOAT)"

# --- bin -> tap ---
$(ITAP): $(BIN_INT)
	mkdir -p "$(BIN_DIR)"
	$(BIN2TAP) -b -o "$@" -a $(LOAD_ADDR_DEC) "$(BIN_INT)"

$(FTAP): $(BIN_FLOAT)
	mkdir -p "$(BIN_DIR)"
	$(BIN2TAP) -b -o "$@" -a $(LOAD_ADDR_DEC) "$(BIN_FLOAT)"

# --- compile rule (keeps int/... and float/... structure) ---
$(EXEC_BUILD_DIR)/%.rel: $(SRC_DIR)/%.c
	mkdir -p "$(dir $@)"
	$(CC) $(CFLAGS) -c -o "$(abspath $@)" "$<"

clean:
	rm -rf "$(EXEC_BUILD_DIR)"
	rm -f "$(ITAP)" "$(FTAP)"
