# -------- test/lib/Makefile --------

BUILD_DIR ?= ../build
BIN_DIR   ?= ../bin

BUILD_DIR := $(abspath $(BUILD_DIR))
BIN_DIR   := $(abspath $(BIN_DIR))

.PHONY: all clean zx cpm

all: zx cpm

zx:
	$(MAKE) -C zx BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

cpm:
	$(MAKE) -C cpm BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

clean:
	$(MAKE) -C zx BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean || true
	$(MAKE) -C cpm BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean || true
