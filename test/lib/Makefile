# -------- test/lib/Makefile --------

BUILD_DIR ?= ../build
BIN_DIR   ?= ../bin

BUILD_DIR := $(abspath $(BUILD_DIR))
BIN_DIR   := $(abspath $(BIN_DIR))

.PHONY: all clean zx

all: zx

zx:
	$(MAKE) -C zx BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

clean:
	$(MAKE) -C zx BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean || true
