# Top-level Makefile: fix clean to work with overridden BUILD_DIR/BIN_DIR

# Docker settings.
DOCKER_IMAGE ?= wischner/sdcc-z80-zx-spectrum:latest
WORKDIR      := $(PWD)

# Output directories (relative to repo root by default).
BUILD_DIR ?= build
BIN_DIR   ?= bin

# Paths as seen inside the container.
ROOT_DOCKER := /work
ifneq ($(filter /%,$(BUILD_DIR)),)
BUILD_DIR_DOCKER := $(BUILD_DIR)
else
BUILD_DIR_DOCKER := $(ROOT_DOCKER)/$(BUILD_DIR)
endif

ifneq ($(filter /%,$(BIN_DIR)),)
BIN_DIR_DOCKER := $(BIN_DIR)
else
BIN_DIR_DOCKER := $(ROOT_DOCKER)/$(BIN_DIR)
endif

# Run container mounting the repo at /work; keep host ownership for outputs.
DOCKER_RUN = docker run --rm \
             -u $$(id -u):$$(id -g) \
             -v "$(WORKDIR):/work" -w /work \
             $(DOCKER_IMAGE)

.PHONY: all tests lib clean

all: tests

tests: lib
	$(DOCKER_RUN) sh -c '$(MAKE) -C test \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" all'

lib:
	$(DOCKER_RUN) sh -c '$(MAKE) -C src \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" all'

clean:
	$(DOCKER_RUN) sh -c '$(MAKE) -C src \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" clean'
	$(DOCKER_RUN) sh -c '$(MAKE) -C test \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" clean'
	rm -rf $(BUILD_DIR) $(BIN_DIR)
