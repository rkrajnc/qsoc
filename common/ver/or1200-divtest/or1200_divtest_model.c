#include <stdio.h>
#include <stdlib.h>

int main()
{
  static const int test_vector[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 20, 21, 33, 66, 75, 80, 81, 90, 99, 100, 101, 1000, 10001,
 1010101, 123456789, 1073741822, 1073741823, 2147483646, 2147483647};

  static const char bin2hex[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
  
  volatile unsigned int x,y;
  volatile int res;

  for (y=0; y<33; y++) {
    for (x=1; x<33; x++) {
      res = test_vector[y]/test_vector[x];
      putchar(bin2hex[(res>>28)&0xf]);
      putchar(bin2hex[(res>>24)&0xf]);
      putchar(bin2hex[(res>>20)&0xf]);
      putchar(bin2hex[(res>>16)&0xf]);
      putchar(bin2hex[(res>>12)&0xf]);
      putchar(bin2hex[(res>> 8)&0xf]);
      putchar(bin2hex[(res>> 4)&0xf]);
      putchar(bin2hex[(res>> 0)&0xf]);
      putchar('\n');
    }
  }

  exit(EXIT_SUCCESS);
}

