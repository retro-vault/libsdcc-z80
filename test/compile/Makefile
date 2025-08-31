ROOT    := $(abspath $(CURDIR)/../..)
BUILD   := $(ROOT)/build/test/compile
BIN     := $(ROOT)/bin
LIB		:= libsdcc-z80

CC      := sdcc
CFLAGS  := --std-c11 -mz80 --debug \
		   --no-std-crt0 --nostdinc --nostdlib \
		   -I.

LD		:= sdcc
LDFLAGS	:= -mz80 -Wl -y \
		   --no-std-crt0 --nostdlib --nostdinc \
		   $(addprefix -L,$(BIN)) \
           -l$(LIB) -p

AS      := sdasz80
ASFLAGS := -x -g

C_SRCS  := $(wildcard *.c)
TESTS   := $(basename $(notdir $(C_SRCS)))
IHXS    := $(addprefix $(BUILD)/,$(addsuffix .ihx,$(TESTS)))

LIB     := libsdcc-z80.lib

.PHONY: all clean

all: $(IHXS)
	@echo "Done!"

$(BUILD)/%.rel: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.ihx: $(BUILD)/%.rel | $(BUILD)
	$(LD) $(LDFLAGS) $(CRT0) $< -o $@

$(BUILD):
	@mkdir -p $(BUILD)

clean:
	@rm -rf $(BUILD)