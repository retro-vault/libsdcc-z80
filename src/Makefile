# ------------------ configuration ------------------

TARGET := libsdcc-z80

# Allow injection from the command line:
#   make BUILD_DIR=/abs/path BIN_DIR=/abs/path
# Defaults are relative to this Makefile.
BUILD_DIR ?= ../build
BIN_DIR   ?= ../bin

# Normalize to absolute paths after injection/defaulting.
BUILD_DIR := $(abspath $(BUILD_DIR))
BIN_DIR   := $(abspath $(BIN_DIR))

# Force SDCC toolchain
override CC := sdcc
override AS := sdasz80
override AR := sdar

# Flags  (NOTE: no -l/-s to avoid polluting src/)
CFLAGS  ?= --std-c11 -mz80 -I. --no-std-crt0 --nostdinc --nostdlib --debug
ASFLAGS ?= -x -g
ARFLAGS ?= -rcs

# ------------------ sources & objects ------------------

C_SRCS := $(shell find . -type f -name '*.c')
S_SRCS := $(shell find . -type f -name '*.s')

C_SRCS_N := $(patsubst ./%,%,$(C_SRCS))
S_SRCS_N := $(patsubst ./%,%,$(S_SRCS))

C_OBJS := $(addprefix $(BUILD_DIR)/,$(C_SRCS_N:.c=.rel))
S_OBJS := $(addprefix $(BUILD_DIR)/,$(S_SRCS_N:.s=.rel))
OBJS   := $(C_OBJS) $(S_OBJS)

LIB := $(BIN_DIR)/$(TARGET).lib

# ------------------ rules ------------------

.PHONY: all clean

all: $(LIB)

$(LIB): $(OBJS) | $(BIN_DIR)
	$(ENVPATH) $(AR) $(ARFLAGS) $@ $(OBJS)

# C -> build/.../file.rel
$(BUILD_DIR)/%.rel: %.c
	mkdir -p $(@D)
	$(ENVPATH) $(CC) $(CFLAGS) -c -o $@ $<

# ASM -> build/.../file.rel  (explicit output path)
$(BUILD_DIR)/%.rel: %.s
	mkdir -p $(@D)
	$(ENVPATH) $(AS) $(ASFLAGS) -o $@ $(abspath $<)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(LIB)
