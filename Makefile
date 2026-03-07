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

# CP/M test-runner image (RunCPM). Mounts repo at /src (matches run_tests.sh).
DOCKER_TEST_IMAGE ?= libsdcc-z80-test
DOCKER_TEST_RUN    = docker run --rm \
                     -v "$(WORKDIR):/src" \
                     $(DOCKER_TEST_IMAGE)

.PHONY: all tests lib clean cpm-tests run-tests docker-test-build docker-test-rebuild

all: tests

tests: lib
	$(DOCKER_RUN) sh -c '$(MAKE) -C test \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" all'

lib:
	$(DOCKER_RUN) sh -c '$(MAKE) -C src \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" all'

# Build the CP/M test-runner Docker image (once; or rebuild with docker-test-rebuild).
docker-test-build:
	docker build -t $(DOCKER_TEST_IMAGE) -f test/Dockerfile.cpm test/

docker-test-rebuild:
	docker build --no-cache -t $(DOCKER_TEST_IMAGE) -f test/Dockerfile.cpm test/

# Build library + CP/M platform lib + .COM test binaries.
cpm-tests: lib
	$(DOCKER_RUN) sh -c '$(MAKE) -C test/lib/cpm \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" all && \
		$(MAKE) -C test/src/execute \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" cpm'

# Run .COM binaries through RunCPM; write results to bin/itest.txt, bin/ftest.txt.
# Builds the Docker image and .COM binaries automatically if needed.
run-tests: docker-test-build cpm-tests
	$(DOCKER_TEST_RUN) /src/test/run_tests.sh itest ftest

clean:
	$(DOCKER_RUN) sh -c '$(MAKE) -C src \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" clean'
	$(DOCKER_RUN) sh -c '$(MAKE) -C test \
		BUILD_DIR="$(BUILD_DIR_DOCKER)" BIN_DIR="$(BIN_DIR_DOCKER)" clean'
	rm -rf $(BUILD_DIR) $(BIN_DIR)
