#! /bin/bash
# Builds the program and writes into the text file for testing
nasm -f elf64 -g -F dwarf todo.asm -o td.o && ld -o todo td.o
printf "Test 1\nTest 2\nTest 3" > todo.txt
