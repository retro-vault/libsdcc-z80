# -------- test/src/compile/Makefile (c-only, link each test separately) --------

ROOT      := $(abspath $(CURDIR)/../../..)
SRC_DIR   := .
BUILD_DIR := $(ROOT)/build/test/compile
BIN_DIR   := $(ROOT)/bin

CC      := sdcc
LD      := sdldz80

CFLAGS  := --std-c11 -mz80 --debug \
           --no-std-crt0 --nostdinc --nostdlib \
           -I. -I$(ROOT)/test/include

LIB_MAIN := $(abspath $(BIN_DIR))/libsdcc-z80.lib

C_SRCS  := $(wildcard $(SRC_DIR)/*.c)
TESTS   := $(basename $(notdir $(C_SRCS)))

IHXS    := $(addprefix $(BUILD_DIR)/,$(addsuffix .ihx,$(TESTS)))
LKS     := $(addprefix $(BUILD_DIR)/,$(addsuffix .lk,$(TESTS)))
OBJS    := $(addprefix $(BUILD_DIR)/,$(addsuffix .rel,$(TESTS)))

.PHONY: all clean
all: $(IHXS)

# Compile each test file
$(BUILD_DIR)/%.rel: $(SRC_DIR)/%.c
	mkdir -p "$(dir $@)"
	$(CC) $(CFLAGS) -c -o "$(abspath $@)" "$<"

# Link each test separately to validate symbols (no tap/bin needed)
$(BUILD_DIR)/%.ihx: $(BUILD_DIR)/%.rel $(LIB_MAIN)
	mkdir -p "$(BUILD_DIR)"
	{ \
	  echo "-i"; \
	  echo "-m"; \
	  echo "-j"; \
	  echo "-o $(abspath $@)"; \
	  echo "$(abspath $(BUILD_DIR)/$*.rel)"; \
	  echo "$(LIB_MAIN)"; \
	} > "$(abspath $(BUILD_DIR)/$*.lk)"
	$(LD) -f "$(abspath $(BUILD_DIR)/$*.lk)"

clean:
	rm -rf "$(BUILD_DIR)"
