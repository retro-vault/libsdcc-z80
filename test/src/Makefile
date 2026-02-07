# -------- test/src/Makefile --------

BUILD_DIR ?= ../build
BIN_DIR   ?= ../bin

BUILD_DIR := $(abspath $(BUILD_DIR))
BIN_DIR   := $(abspath $(BIN_DIR))

.PHONY: all clean compile execute

all: compile execute

compile:
	$(MAKE) -C compile BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

execute:
	$(MAKE) -C execute BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

clean:
	$(MAKE) -C compile BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean || true
	$(MAKE) -C execute BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean || true
