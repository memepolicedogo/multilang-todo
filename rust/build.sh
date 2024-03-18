#!/bin/bash
printf "Test 1\nTest 2\nTest 3\n" > todo.txt
rustc todo.rs -o todo
