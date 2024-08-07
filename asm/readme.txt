Requirements:
x86-64 linux system
nasm assembler
ld linker

Usage:
List items in todo list:
$ todo
Add an item to todo list:
$ todo "Item to be added"
Remove an item from todo list:
$ todo -d {index}
*Index starts at 0
Clear todo list:
$ todo -c

Limitations:

Line numbers are limited to 2 digits. This could be changed
but it really doesn't matter, if you have more than 99 things on your list you have bigger problems
