# -------- test/execute/Makefile (ZX Spectrum exec + absolute .lk + TAP) --------

ROOT        := $(abspath $(CURDIR)/../../..)
SRC_DIR     := .
BUILD_DIR   := $(ROOT)/build/test/execute
BIN_DIR     := $(ROOT)/bin

TARGET      := ftest
OUT_BASE    := $(BUILD_DIR)/$(TARGET)

LOAD_ADDR_HEX ?= 0x8000
LOAD_ADDR_DEC ?= 32768

# Library (use absolute full path; no -l)
LIB_NAME   := libsdcc-z80.lib
LIB_PATH   := $(abspath $(BIN_DIR))/$(LIB_NAME)

CC       := sdcc
AS       := sdasz80
LD       := sdldz80
OBJCOPY  := sdobjcopy
BIN2TAP  := bin2tap

CFLAGS   := --std-c11 -mz80 --debug \
            --no-std-crt0 --nostdinc --nostdlib \
            -I. -Izx -I$(ROOT)/include
ASFLAGS  := -plosgff

CRT0_SRC := $(firstword $(wildcard $(SRC_DIR)/../zx/crt0*.s))
CRT0_OBJ := $(abspath $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.rel,$(CRT0_SRC)))

S_SRCS   := $(filter-out $(CRT0_SRC), $(wildcard $(SRC_DIR)/*.s) $(wildcard $(SRC_DIR)/../zx/*.s))
C_SRCS   := $(wildcard $(SRC_DIR)/*.c)  $(wildcard $(SRC_DIR)/../zx/*.c)

S_OBJS   := $(abspath $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.rel,$(S_SRCS)))
C_OBJS   := $(abspath $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.rel,$(C_SRCS)))
OBJS     := $(S_OBJS) $(C_OBJS)

IHX      := $(abspath $(OUT_BASE).ihx)
BIN      := $(abspath $(OUT_BASE).bin)
LINKFK   := $(abspath $(OUT_BASE).lk)
TAP      := $(abspath $(BIN_DIR)/$(TARGET).tap)

.PHONY: all clean
all: $(TAP)

# --- link via generated .lk (ALL ABSOLUTE PATHS; no -l) ---
$(IHX): $(CRT0_OBJ) $(OBJS)
	mkdir -p $(BUILD_DIR)
	{ \
	  echo "-b_CODE=$(LOAD_ADDR_HEX)"; \
	  echo "-i"; \
	  echo "-m"; \
	  echo "-j"; \
	  echo "-o $(IHX)"; \
	  echo "$(CRT0_OBJ)"; \
	  for obj in $(OBJS); do echo "$$obj"; done; \
	  echo "$(LIB_PATH)"; \
	} > "$(LINKFK)"
	$(LD) -f "$(LINKFK)"

# --- ihx -> bin ---
$(BIN): $(IHX)
	mkdir -p $(dir $@)
	$(OBJCOPY) -I ihex -O binary "$(IHX)" "$(BIN)"

# --- bin -> tap ---
$(TAP): $(BIN)
	mkdir -p "$(BIN_DIR)"
	$(BIN2TAP) -b -o "$(TAP)" -a $(LOAD_ADDR_DEC) "$(BIN)"

# --- build rules (preserve subdirs) ---
$(CRT0_OBJ): $(CRT0_SRC)
	mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o "$@" "$<"

$(BUILD_DIR)/%.rel: $(SRC_DIR)/%.s
	mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o "$(abspath $@)" "$<"

$(BUILD_DIR)/%.rel: $(SRC_DIR)/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c -o "$(abspath $@)" "$<"

clean:
	rm -rf "$(BUILD_DIR)"
	rm -rf "$(BIN_DIR)"
