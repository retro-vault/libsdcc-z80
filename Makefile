# Docker settings.
DOCKER_IMAGE ?= wischner/sdcc-z80-zx-spectrum:latest
WORKDIR      := $(PWD)

# Run container mounting the repo at /work; keep host ownership for outputs
DOCKER_RUN = docker run --rm \
             -u $$(id -u):$$(id -g) \
             -v "$(WORKDIR):/work" -w /work \
             $(DOCKER_IMAGE)

# Default: build lib then run link-only tests
all: tests
	
tests: lib
	$(DOCKER_RUN) sh -c 'make -C test all'

# Build library inside Docker using src/Makefile (artifacts -> ./build & ./bin)
lib: 
	$(DOCKER_RUN) sh -c 'make -C src all'

clean:
	rm -rf build
	rm -rf bin

.PHONY: all tests lib clean
