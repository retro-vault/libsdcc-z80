# -------- test/lib/cpm/Makefile --------

TARGET := libcpm
ROOT   := $(abspath ../../..)

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

CPM_BUILD_DIR := $(BUILD_DIR)/test/lib/cpm

override AS := sdasz80
override AR := sdar

ASFLAGS ?= -x -g
ARFLAGS ?= -rcs

CRT0_SRC := crt0.s
LIB_SRCS := cputc.s cputs.s cinit.s cclear.s

LIB_OBJS := $(addprefix $(CPM_BUILD_DIR)/,$(LIB_SRCS:.s=.rel))

LIB     := $(BIN_DIR)/$(TARGET).lib
CRT0REL := $(BIN_DIR)/crt0cpm.rel

.PHONY: all clean

all: $(LIB) $(CRT0REL)

$(LIB): $(LIB_OBJS) | $(BIN_DIR)
	$(AR) $(ARFLAGS) $@ $(LIB_OBJS)

$(CRT0REL): $(CRT0_SRC) | $(BIN_DIR)
	$(AS) $(ASFLAGS) -o $@ $(abspath $<)

$(CPM_BUILD_DIR)/%.rel: %.s | $(CPM_BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $(abspath $<)

$(CPM_BUILD_DIR):
	mkdir -p $@

$(BIN_DIR):
	mkdir -p $@

clean:
	rm -rf $(CPM_BUILD_DIR)
	rm -f $(LIB) $(CRT0REL)
