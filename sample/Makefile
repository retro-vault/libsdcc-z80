.PHONY:	all
all:

	# Compile crt0.s
	sdasz80 -xlos -g crt0.s

	# Compile test.c
	sdcc -o test.rel \
		-c --std-c11 -mz80 --debug \
		--nostdinc --no-std-crt0 --nostdinc --nostdlib \
		test.c
		
	# Link both
	sdcc -o test.ihx \
		-mz80 -Wl -y --code-loc 0x8000 --data-loc 0x8600 \
		--std-c11 -mz80 --debug\
		--no-std-crt0 --nostdinc --nostdlib \
		-L../bin -llibsdcc-z80 \
		crt0.rel test.rel
	
	# Finally, convert ihx to binary
	sdobjcopy -I ihex -O binary test.ihx test.bin
	
.PHONY: clean
clean:
	# Remoe everything except source files
	rm -f *.lst
	rm -f *.sym
	rm -f *.asm
	rm -f *.ihx
	rm -f *.lk
	rm -f *.noi	
	rm -f *.map
	rm -f *.rel
	rm -f *.?db	
	rm -f *.bin
