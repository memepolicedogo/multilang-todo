
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  char filename[] = "todo.txt";
  if (argc == 1) {
    // Print file
    FILE *fptr = fopen(filename, "r");
    int reading = 1;
    char readBuffer[1024];
    int lineNum = 0;
    printf("%3i: ", 0);
    while (reading) {
      int readLen = fread(readBuffer, 1, 1024, fptr);
      if (readLen < 1024) {
        reading = 0;
      }
      for (int i = 0; i < readLen; i++) {
        printf("%c", readBuffer[i]);
        if (readBuffer[i] == '\n') {
          lineNum++;
          if (i + 1 < readLen || reading) {
            printf("%3i: ", lineNum);
          }
        }
      }
    }
    fclose(fptr);
  } else if (argv[1][0] == '-') {
    if (argv[1][1] != 'd' || argc < 3) {
      printf("Invalid argument");
      return 0;
    }
    // Remove line
    FILE *fptr = fopen(filename, "r+");
    FILE *tmpptr = fopen("todo.tmp", "w");
    int popIndex = (int)strtol(argv[2], NULL, 10);
    if (errno == ERANGE) {
      printf("Invalid line number");
    }
    int reading = 1;
    char readBuffer[1024];
    char writeBuffer[1024];
    while (reading) {
      int delLen = 0;
      int readLen = fread(readBuffer, 1, 1024, fptr);
      if (readLen < 1024) {
        reading = 0;
      }
      int lineNum = 0;
      for (int c = 0; c < readLen; c++) {
        char current = readBuffer[c];
        if (current == '\n') {
          lineNum++;
        }
        if (lineNum != popIndex) {
          writeBuffer[c - delLen] = current;
        } else {
          delLen++;
        }
      }
      fwrite(writeBuffer, 1, readLen - delLen, tmpptr);
    }
    fclose(fptr);
    fclose(tmpptr);
    remove(filename);
    rename("todo.tmp", filename);
  } else {
    // Add to file
    FILE *fptr = fopen(filename, "a");
    fwrite(argv[1], 1, strlen(argv[1]), fptr);
    fwrite("\n", 1, 1, fptr);
    fclose(fptr);
  }
  return 0;
}
