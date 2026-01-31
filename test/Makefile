# -------- test/Makefile --------
.PHONY: all lib src clean

all: src

# Build test support library first
lib:
	$(MAKE) -C lib all

# Build tests (depends on lib)
src: lib
	$(MAKE) -C src all

clean:
	$(MAKE) -C lib clean || true
	$(MAKE) -C src clean || true
