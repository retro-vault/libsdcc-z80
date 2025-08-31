# -------- test/execute/Makefile (ZX Spectrum exec + TAP via bin2tap) --------

TOP     := $(abspath $(CURDIR)/../..)
OUT     := $(TOP)/build/test/execute
BIN     := $(TOP)/bin
LIB     := libsdcc-z80

# ZX params
ZX_ADDR := 32768              # 0x8000
ZX_NAME := test               # TAP filename inside header

# tools
CC      := sdcc
AS      := sdasz80
OBJCOPY := sdobjcopy
BIN2TAP := bin2tap            # from fuse-emulator-utils

# compile / link flags
CFLAGS  := --std-c11 -mz80 --debug \
           --no-std-crt0 --nostdinc --nostdlib \
           -I. -Izx -I$(TOP)/include
ASFLAGS := -plosgff
LDFLAGS := -mz80 --no-std-crt0 --nostdlib --nostdinc \
           -Wl -b_CODE=0x8000 -Wl -b_DATA=0x9000 -Wl -b_BSS=0x9800 \
           -Wl -y \
           $(addprefix -L,$(BIN)) -l$(LIB) -p

# sources (this dir and optional zx/)
S_SRCS  := $(filter-out crt0_zx.s,$(wildcard *.s)) $(wildcard zx/*.s)
C_SRCS  := $(wildcard *.c) $(wildcard zx/*.c)

# objects (mirror subdirs under OUT)
S_OBJS  := $(patsubst %.s,$(OUT)/%.rel,$(S_SRCS))
C_OBJS  := $(patsubst %.c,$(OUT)/%.rel,$(C_SRCS))
OBJS    := $(S_OBJS) $(C_OBJS)

CRT0    := $(OUT)/crt0_zx.rel
IHX     := $(OUT)/test.ihx
BINOUT  := $(OUT)/test.bin
# final TAP goes in bin/
TAP     := $(BIN)/test.tap

.PHONY: all clean

all: $(TAP)
	@echo "ZX exec ready: $(notdir $(BINOUT))  $(notdir $(TAP))"

# --- assemble crt0 first (note: -o before input for sdasz80) ---
$(CRT0): crt0_zx.s
	@mkdir -p $(dir $@)
	@echo "[as] $< -> $@"
	$(AS) $(ASFLAGS) -o $@ $<

# --- assemble .s -> .rel (preserve subdirs) ---
$(OUT)/%.rel: %.s
	@mkdir -p $(dir $@)
	@echo "[as] $< -> $@"
	$(AS) $(ASFLAGS) -o $@ $<

# --- compile .c -> .rel (preserve subdirs) ---
$(OUT)/%.rel: %.c
	@mkdir -p $(dir $@)
	@echo "[cc] $< -> $@"
	$(CC) $(CFLAGS) -c -o $@ $<

# --- link all objects into one .ihx (CRT0 first) ---
$(IHX): $(CRT0) $(OBJS)
	@mkdir -p $(dir $@)
	@echo "[link] $(notdir $@)"
	$(CC) $(LDFLAGS) $(CRT0) $(OBJS) -o $@

# --- convert ihx -> bin using sdobjcopy (SDCC tool) ---
$(BINOUT): $(IHX)
	@mkdir -p $(dir $@)
	@echo "[objcopy] $(notdir $@)"
	$(OBJCOPY) -I ihex -O binary $< $@

# --- wrap BIN into TAP using bin2tap (from fuse-emulator-utils) ---
# Typical syntax: bin2tap -o out.tap -a <start_addr> -n <name> in.bin
$(TAP): $(BINOUT)
	@mkdir -p $(dir $@)
	@echo "[bin2tap] $(notdir $@)"
	$(BIN2TAP) -o $@ -a $(ZX_ADDR) $(BINOUT)


clean:
	@echo "[test/execute/clean] removing $(OUT)"
	@rm -rf $(OUT)
