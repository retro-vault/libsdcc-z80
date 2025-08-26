# ------------------ configuration ------------------

# Library name (no extension)
TARGET          ?= libsdcc-z80

# Intermediate and final output dirs
BUILD_DIR       := $(abspath ../build)
BIN_DIR         := $(abspath ../bin)

# SDCC toolchain
CC               = sdcc
AS               = sdasz80
AR               = sdar           # force sdar

# Typical SDCC flags (adjust as you need)
CFLAGS          = --std-c11 -mz80 -I. --no-std-crt0 --nostdinc --nostdlib --debug
ASFLAGS         = -xlos -g
ARFLAGS         = -rcs

# Docker integration
REPO_ROOT       := $(abspath ..)
DOCKER_IMAGE    ?= sdcc-env:latest
DOCKER_RUN      := docker run --rm -v "$(REPO_ROOT):/work" -w /work/src $(DOCKER_IMAGE)

# If we're inside the container, RUN=empty (run tools directly).
# Otherwise, RUN prefixes commands with docker.
ifneq ("$(wildcard /opt/sdcc/bin/sdcc)","")
  RUN :=
else
  RUN := $(DOCKER_RUN)
endif

# Always ensure /opt/sdcc/bin is on PATH (works both inside and outside Docker)
ENVPATH := env PATH=/opt/sdcc/bin:$$PATH

# ------------------ sources & objects ------------------

# Find all C/ASM sources recursively relative to src/
C_SRCS := $(shell find . -type f -name '*.c')
S_SRCS := $(shell find . -type f -name '*.s')

# Normalize paths (strip leading ./)
C_SRCS_N := $(patsubst ./%,%,$(C_SRCS))
S_SRCS_N := $(patsubst ./%,%,$(S_SRCS))

# Map to build tree, preserving subdirectories
C_OBJS := $(addprefix $(BUILD_DIR)/,$(C_SRCS_N:.c=.rel))
S_OBJS := $(addprefix $(BUILD_DIR)/,$(S_SRCS_N:.s=.rel))
OBJS   := $(C_OBJS) $(S_OBJS)

# Final library output
LIB    := $(BIN_DIR)/$(TARGET).lib

# ------------------ rules ------------------

.PHONY: all clean print

all: $(LIB)

$(LIB): $(OBJS) | $(BIN_DIR)
	@echo "[make] archiving -> $@"
	@$(RUN) $(ENVPATH) $(AR) $(ARFLAGS) $@ $(OBJS)

# C -> .rel
$(BUILD_DIR)/%.rel: %.c
	@echo "[cc] $< -> $@"
	@mkdir -p $(@D)
	@$(RUN) $(ENVPATH) $(CC) $(CFLAGS) -c -o $@ $<

# ASM -> .rel
$(BUILD_DIR)/%.rel: %.s
	@echo "[as] $< -> $@"
	@mkdir -p $(@D)
	@$(RUN) $(ENVPATH) $(AS) $(ASFLAGS) -o $@ $<

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

clean:
	@echo "[make] removing $(BUILD_DIR) and $(BIN_DIR)"
	@rm -rf $(BUILD_DIR) $(BIN_DIR)

print:
	@echo "TARGET     = $(TARGET)"
	@echo "BUILD_DIR  = $(BUILD_DIR)"
	@echo "BIN_DIR    = $(BIN_DIR)"
	@echo "DOCKER_IMG = $(DOCKER_IMAGE)"
	@echo "RUN prefix = '$(RUN)'"
	@echo
	@echo "C_SRCS:" ; printf "  %s\n" $(C_SRCS_N)
	@echo "S_SRCS:" ; printf "  %s\n" $(S_SRCS_N)
	@echo "OBJS:"   ; printf "  %s\n" $(OBJS)
