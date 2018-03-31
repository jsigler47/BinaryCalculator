BinCalc: BinCalc.asm BinCalc.o
	ld -m elf_i386 BinCalc.o -o BinCalc
BinCalc.o: BinCalc.asm
	nasm -f elf32 -g -F dwarf BinCalc.asm
clean:
	rm -f BinCalc.o

