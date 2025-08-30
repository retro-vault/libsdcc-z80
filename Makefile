# Targets.
TARGET ?= libsdcc-z80

# Docker settings.
DOCKER_IMAGE ?= sdcc-env:latest
DOCKERFILE   ?= Dockerfile
WORKDIR      := $(PWD)

# Run container mounting the repo; ensure SDCC is on PATH
DOCKER_RUN = docker run --rm -v "$(WORKDIR):/work" -w /work $(DOCKER_IMAGE) \
             env PATH=/opt/sdcc/bin:$$PATH

# Default: build lib then run link-only tests
all: $(TARGET) check

docker-image:
	@echo "[host] building docker image $(DOCKER_IMAGE) ..."
	@docker build -f $(DOCKERFILE) -t $(DOCKER_IMAGE) .

# Build library inside Docker using src/Makefile (artifacts -> ./build & ./bin)
$(TARGET): docker-image
	@echo "[host] building (inside docker) -> bin/$(TARGET).lib"
	@$(DOCKER_RUN) sh -c 'make -C src TARGET=$(TARGET) all'

# Run link-only tests inside Docker after building the library
check: $(TARGET)
	@echo "[host] running link checks (inside docker) against bin/$(TARGET).lib"
	@$(DOCKER_RUN) sh -c 'make -C test LIB=../bin/$(TARGET).lib all'

build: $(TARGET)

rebuild:
	@$(DOCKER_RUN) sh -c 'make -C src clean'
	@$(MAKE) all

clean:
	@echo "[host] removing ./build"
	@rm -rf build
	@rm -rf bin

.PHONY: all docker-image $(TARGET) build rebuild clean check
