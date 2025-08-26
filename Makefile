# Targets.
TARGET ?= libsdcc-z80

# Docker settings.
DOCKER_IMAGE ?= sdcc-env:latest
DOCKERFILE   ?= Dockerfile
WORKDIR      := $(PWD)

# Run container mounting the repo; ensure SDCC is on PATH
DOCKER_RUN = docker run --rm -v "$(WORKDIR):/work" -w /work $(DOCKER_IMAGE) \
             env PATH=/opt/sdcc/bin:$$PATH

# Top level targets.
all: $(TARGET)

docker-image:
	@echo "[host] building docker image $(DOCKER_IMAGE) ..."
	@docker build -f $(DOCKERFILE) -t $(DOCKER_IMAGE) .

# Build TAP inside Docker using src/Makefile (artifacts go to ./build)
$(TARGET): docker-image
	@echo "[host] building (inside docker) -> build/$(TARGET).lib"
	@$(DOCKER_RUN) sh -c 'make -C src TARGET=$(TARGET) all'

build: $(TARGET)

rebuild:
	@$(DOCKER_RUN) sh -c 'make -C src clean'
	@$(MAKE) $(TARGET)

clean:
	@echo "[host] removing ./build"
	@rm -rf build

.PHONY: all docker-image $(TARGET) build rebuild clean