# -------- test/src/Makefile --------
.PHONY: all compile execute clean

all: compile execute

compile:
	$(MAKE) -C compile all

execute:
	$(MAKE) -C execute all

clean:
	$(MAKE) -C compile clean || true
	$(MAKE) -C execute clean || true
