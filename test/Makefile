# -------- test/Makefile --------

# Allow injection from the command line:
#   make BUILD_DIR=... BIN_DIR=...
# Defaults are repo-root build/bin when invoked from /test.
BUILD_DIR ?= ../build
BIN_DIR   ?= ../bin

# IMPORTANT:
# Normalize once here so sub-makes never see relative paths that change meaning
# when they run in deeper directories (e.g. test/src/compile).
BUILD_DIR := $(abspath $(BUILD_DIR))
BIN_DIR   := $(abspath $(BIN_DIR))

.PHONY: all lib src clean

all: lib src

lib:
	$(MAKE) -C lib BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

src:
	$(MAKE) -C src BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all

clean:
	$(MAKE) -C lib BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean
	$(MAKE) -C src BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" clean
