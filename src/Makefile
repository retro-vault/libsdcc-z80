# ------------------ configuration ------------------

TARGET     ?= libsdcc-z80

BUILD_DIR  := $(abspath ../build)
BIN_DIR    := $(abspath ../bin)

# Force SDCC toolchain
override CC := sdcc
override AS := sdasz80
override AR := sdar

# Flags  (NOTE: no -l/-s to avoid polluting src/)
CFLAGS  ?= --std-c11 -mz80 -I. --no-std-crt0 --nostdinc --nostdlib --debug
ASFLAGS ?= -x -g
ARFLAGS ?= -rcs

ENVPATH := env PATH=/opt/sdcc/bin:$$PATH

# ------------------ sources & objects ------------------

C_SRCS := $(shell find . -type f -name '*.c')
S_SRCS := $(shell find . -type f -name '*.s')

# Optionally exclude startup/libc bits from the lib:
S_EXCLUDE := crt0.s %/crt0.s memmove.s %/memmove.s

C_SRCS_N := $(patsubst ./%,%,$(C_SRCS))
S_SRCS_N := $(filter-out $(S_EXCLUDE),$(patsubst ./%,%,$(S_SRCS)))

C_OBJS := $(addprefix $(BUILD_DIR)/,$(C_SRCS_N:.c=.rel))
S_OBJS := $(addprefix $(BUILD_DIR)/,$(S_SRCS_N:.s=.rel))
OBJS   := $(C_OBJS) $(S_OBJS)

LIB    := $(BIN_DIR)/$(TARGET).lib

# ------------------ rules ------------------

.PHONY: all clean print

all: $(LIB)

$(LIB): $(OBJS) | $(BIN_DIR)
	@echo "[ar] $@"
	@$(ENVPATH) $(AR) $(ARFLAGS) $@ $(OBJS)

# C -> build/.../file.rel
$(BUILD_DIR)/%.rel: %.c
	@echo "[cc] $< -> $@"
	@mkdir -p $(@D)
	@$(ENVPATH) $(CC) $(CFLAGS) -c -o $@ $<

# ASM -> build/.../file.rel  (explicit output path)
$(BUILD_DIR)/%.rel: %.s
	@echo "[as] $< -> $@"
	@mkdir -p $(@D)
	@$(ENVPATH) $(AS) $(ASFLAGS) -o $@ $(abspath $<)

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

clean:
	@echo "[src/clean] removing $(BUILD_DIR)"
	@rm -rf $(BUILD_DIR)

print:
	@echo "TARGET    = $(TARGET)"
	@echo "BUILD_DIR = $(BUILD_DIR)"
	@echo "BIN_DIR   = $(BIN_DIR)"
	@echo "OBJS:" ; printf "  %s\n" $(OBJS)
