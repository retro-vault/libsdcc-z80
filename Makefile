# We only allow compilation on Linux.
ifneq ($(shell uname), Linux)
ifndef INSIDE_DOCKER
$(error OS must be Linux!)
endif
endif

# --------------------------------------------------------------------------
# Folders
# --------------------------------------------------------------------------
export ROOT       := $(realpath .)
export BUILD_DIR  ?= $(ROOT)/build
export BIN_DIR    ?= $(ROOT)/bin

# --------------------------------------------------------------------------
# Library names
# --------------------------------------------------------------------------
export TARGET     := libsdcc-z80

# --------------------------------------------------------------------------
# Tools and flags
# --------------------------------------------------------------------------
export CC         := sdcc
export AS         := sdasz80
export AR         := sdar
export CPP        := sdcpp
export LD         := sdldz80

# --------------------------------------------------------------------------
# Docker (on by default). Set DOCKER=off for a native build.
# --------------------------------------------------------------------------
DOCKER            ?= on

DOCKER_IMAGE      := wischner/sdcc-z80
DOCKER_RUN        := docker run --rm \
                     -v "$(ROOT)":/src \
                     -w /src \
                     -e INSIDE_DOCKER=1 \
                     --user $(shell id -u):$(shell id -g) \
                     $(DOCKER_IMAGE)

DOCKER_TEST_IMAGE := libsdcc-z80-test
DOCKER_TEST_RUN   := docker run --rm \
                     -v "$(ROOT)":/src \
                     $(DOCKER_TEST_IMAGE)

# --------------------------------------------------------------------------
# Native tool check (only when building without Docker)
# --------------------------------------------------------------------------
ifndef INSIDE_DOCKER
ifeq ($(DOCKER),off)
REQUIRED = $(CC) $(AR) $(AS) $(CPP) $(LD) sdobjcopy
K := $(foreach exec,$(REQUIRED),\
    $(if $(shell which $(exec)),,$(error "$(exec) not found. Install SDCC or use DOCKER=on.")))
endif
endif

# --------------------------------------------------------------------------
# Internal native build (called directly or from inside Docker)
# --------------------------------------------------------------------------
SUBDIRS := src

.PHONY: _build
_build: $(BUILD_DIR) $(SUBDIRS)
	cp --dereference "$(BUILD_DIR)/$(TARGET).lib" "$(BIN_DIR)"

.PHONY: $(BUILD_DIR)
$(BUILD_DIR):
	rm -rf "$(BUILD_DIR)" "$(BIN_DIR)"
	mkdir -p "$(BUILD_DIR)" "$(BIN_DIR)"

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ BUILD_DIR="$(BUILD_DIR)"

# --------------------------------------------------------------------------
# Default build
# --------------------------------------------------------------------------
.DEFAULT_GOAL := all

ifeq ($(DOCKER),on)
.PHONY: all
all:
	$(DOCKER_RUN) make _build BUILD_DIR=/src/build BIN_DIR=/src/bin
else
.PHONY: all
all: _build
endif

# --------------------------------------------------------------------------
# Tests
# --------------------------------------------------------------------------
ifeq ($(DOCKER),on)
.PHONY: test
test: docker-test-build
	$(DOCKER_RUN) sh -c "make _build BUILD_DIR=/src/build BIN_DIR=/src/bin && make -C test BUILD_DIR=/src/build BIN_DIR=/src/bin all"
	$(DOCKER_TEST_RUN) /src/test/run_tests.sh itest ftest
else
.PHONY: test
test: _build
	$(MAKE) -C test BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)" all
endif

.PHONY: docker-test-build
docker-test-build:
	docker build -t $(DOCKER_TEST_IMAGE) -f test/Dockerfile.cpm test/

.PHONY: docker-test-rebuild
docker-test-rebuild:
	docker build --no-cache -t $(DOCKER_TEST_IMAGE) -f test/Dockerfile.cpm test/

# Backward-compatible aliases.
.PHONY: lib cpm-tests run-tests
lib: all

cpm-tests:
	$(MAKE) test DOCKER=off BUILD_DIR="$(BUILD_DIR)" BIN_DIR="$(BIN_DIR)"

run-tests: test

# --------------------------------------------------------------------------
# Clean
# --------------------------------------------------------------------------
.PHONY: clean
clean:
	rm -rf "$(BUILD_DIR)" "$(BIN_DIR)"

# --------------------------------------------------------------------------
# Help
# --------------------------------------------------------------------------
.PHONY: help
help:
	@echo "Usage: make [target] [VARIABLE=value ...]"
	@echo ""
	@echo "Targets:"
	@echo "  (default)    Build the library"
	@echo "  test         Build tests; also run them when DOCKER=on"
	@echo "  clean        Remove build/ and bin/"
	@echo "  docker-test-build    Build the RunCPM Docker image"
	@echo "  docker-test-rebuild  Rebuild the RunCPM Docker image without cache"
	@echo ""
	@echo "Variables:"
	@echo "  DOCKER=on           Build inside Docker (default)"
	@echo "  DOCKER=off          Build natively (requires SDCC on PATH)"
	@echo "  BUILD_DIR=<path>    Override intermediate build directory (default: build/)"
	@echo "  BIN_DIR=<path>      Override output directory (default: bin/)"
