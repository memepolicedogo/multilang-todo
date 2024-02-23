Requirements:
64 bit linux computer
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


Limitations:
Listing is capped at 1024 characters, including newlines, 
increasing this limit is the next priority.

Line numbers are limited to 8 digits. This could be changed
but it really doesn't matter
