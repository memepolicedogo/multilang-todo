#!/usr/bin/python3
import sys

args = sys.argv[1:]
if len(args) == 0:
    with open('todo.txt') as todoFile:
        lineNum = 0
        for line in todoFile:
            print(f'{lineNum}: {line}', end='')
            lineNum += 1
    exit()
match args[0]:
    case "-d":
        popIndex = int(args[1])
        with open('todo.txt', 'r') as todoFile:
            fileLines = todoFile.read().split("\n")[:-1]
        with open('todo.txt', 'w') as todoFile:
            todoFile.seek(0)
            lineNum = 0
            for line in fileLines:
                if lineNum != popIndex:
                    todoFile.write(line)
                    todoFile.write('\n')
                else:
                    print(f"Removed \"{line}\"")
                lineNum += 1
            exit()
    case _:
        with open('todo.txt', 'r') as todoFile:
            fileText = todoFile.read()
        with open('todo.txt', 'a') as todoFile:
            todoFile.write(args[0])
            todoFile.write('\n')
        exit()
