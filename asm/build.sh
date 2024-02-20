#! /bin/bash
# Builds the program and writes into the text file for testing
nasm -f elf64 -g -F dwarf todo.asm -o td.o && ld -o todo td.o
printf "Test1\nTest2\nTest3\n" > todo.txt
