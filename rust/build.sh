#!/bin/bash
printf "Test 1\nTest 2\nTest 3\n" > todo.txt
cd todo
cargo build && cd .. && echo "Running:" && todo/target/debug/todo -d 1

