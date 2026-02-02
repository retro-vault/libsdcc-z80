# -------- test/lib/zx/Makefile --------

TARGET := libzx
ROOT   := $(abspath ../../..)

# Injected by parent makefiles. If relative, treat as repo-root relative.
BUILD_DIR ?= build
BIN_DIR   ?= bin

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

ZX_BUILD_DIR := $(BUILD_DIR)/test/lib/zx

# Toolchain
override CC := sdcc
override AS := sdasz80
override AR := sdar

CFLAGS  ?= --std-c11 -mz80 --debug \
           --no-std-crt0 --nostdinc --nostdlib \
           -I$(ROOT)/test/include

ASFLAGS ?= -x -g
ARFLAGS ?= -rcs

# ------------------ sources ------------------

CRT0_SRC := crt0.s

C_SRCS := $(shell find . -type f -name '*.c')
S_SRCS := $(shell find . -type f -name '*.s')

C_SRCS_N := $(patsubst ./%,%,$(C_SRCS))
S_SRCS_N := $(patsubst ./%,%,$(S_SRCS))

# Exclude crt0 from library objects
S_LIB_SRCS := $(filter-out $(CRT0_SRC),$(S_SRCS_N))

C_OBJS := $(addprefix $(ZX_BUILD_DIR)/,$(C_SRCS_N:.c=.rel))
S_OBJS := $(addprefix $(ZX_BUILD_DIR)/,$(S_LIB_SRCS:.s=.rel))
OBJS   := $(C_OBJS) $(S_OBJS)

LIB     := $(BIN_DIR)/$(TARGET).lib
CRT0REL := $(BIN_DIR)/crt0zx.rel

# ------------------ rules ------------------

.PHONY: all clean

all: $(LIB) $(CRT0REL)

# --- library ---
$(LIB): $(OBJS) | $(BIN_DIR)
	$(AR) $(ARFLAGS) $@ $(OBJS)

# --- crt0 ---
$(CRT0REL): $(CRT0_SRC) | $(BIN_DIR)
	$(AS) $(ASFLAGS) -o $@ $(abspath $<)

# --- C -> .rel ---
$(ZX_BUILD_DIR)/%.rel: %.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

# --- ASM -> .rel ---
$(ZX_BUILD_DIR)/%.rel: %.s
	mkdir -p $(@D)
	$(AS) $(ASFLAGS) -o $@ $(abspath $<)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -rf $(ZX_BUILD_DIR)
	rm -f $(LIB) $(CRT0REL)
