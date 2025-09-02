# Docker settings.
DOCKER_IMAGE ?= sdcc-env:latest
DOCKERFILE   ?= Dockerfile
WORKDIR      := $(PWD)

# Run container mounting the repo; ensure SDCC is on PATH
DOCKER_RUN = docker run --rm -v "$(WORKDIR):/work" -w /work $(DOCKER_IMAGE) \
             env PATH=/opt/sdcc/bin:$$PATH

# Default: build lib then run link-only tests
all: tests
	

tests: docker-image lib
	$(DOCKER_RUN) sh -c 'make -C test all'

# Build library inside Docker using src/Makefile (artifacts -> ./build & ./bin)
lib: 
	$(DOCKER_RUN) sh -c 'make -C src all'

docker-image:
	docker build -f $(DOCKERFILE) -t $(DOCKER_IMAGE) .

clean:
	rm -rf build
	rm -rf bin

.PHONY: all docker-image tests lib clean
