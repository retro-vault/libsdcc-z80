# -------- test/src/execute/Makefile --------
# Builds CP/M .COM test binaries from C sources.

ROOT := $(abspath $(CURDIR)/../../..)
SRC_DIR := .

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

CFLAGS := --std-c11 -mz80 --debug \
          --no-std-crt0 --nostdinc --nostdlib \
          -I. -I$(ROOT)/test/include

CPM_LOAD_HEX ?= 0x0100

CRT0_CPM := $(BIN_DIR)/crt0cpm.rel
LIB_MAIN := $(BIN_DIR)/libsdcc-z80.lib
LIB_CPM  := $(BIN_DIR)/libcpm.lib

ICOM := $(BIN_DIR)/itest.com
FCOM := $(BIN_DIR)/ftest.com

INT_C_SRCS   := $(wildcard $(SRC_DIR)/int/*.c)
FLOAT_C_SRCS := $(wildcard $(SRC_DIR)/float/*.c)

INT_C_OBJS_CPM   := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/cpm/%.rel,$(INT_C_SRCS)))
FLOAT_C_OBJS_CPM := $(abspath $(patsubst $(SRC_DIR)/%.c,$(EXEC_BUILD_DIR)/cpm/%.rel,$(FLOAT_C_SRCS)))

IHX_INT_CPM  := $(EXEC_BUILD_DIR)/cpm/int/itest.ihx
LK_INT_CPM   := $(EXEC_BUILD_DIR)/cpm/int/itest.lk

IHX_FLOAT_CPM := $(EXEC_BUILD_DIR)/cpm/float/ftest.ihx
LK_FLOAT_CPM  := $(EXEC_BUILD_DIR)/cpm/float/ftest.lk

.PHONY: all clean cpm

all: cpm

cpm: $(ICOM) $(FCOM)

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

# sdobjcopy produces a flat binary starting at 0x0100 — a valid .COM file.
$(ICOM): $(IHX_INT_CPM) | $(BIN_DIR)
	$(OBJCOPY) -I ihex -O binary "$(IHX_INT_CPM)" "$@"

$(FCOM): $(IHX_FLOAT_CPM) | $(BIN_DIR)
	$(OBJCOPY) -I ihex -O binary "$(IHX_FLOAT_CPM)" "$@"

$(EXEC_BUILD_DIR)/cpm/%.rel: $(SRC_DIR)/%.c
	mkdir -p "$(dir $@)"
	$(CC) $(CFLAGS) -c -o "$(abspath $@)" "$<"

$(BIN_DIR):
	mkdir -p "$(BIN_DIR)"

clean:
	rm -rf "$(EXEC_BUILD_DIR)"
	rm -f "$(ICOM)" "$(FCOM)"
