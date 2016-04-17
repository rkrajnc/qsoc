// or1200-divtest.c
// 2016, rok.krajnc@gmail.com


//// exit() ////
#define NOP_EXIT 0x0001
void exit(int val)
{
  asm volatile ("l.add r3,r0,%0": : "r" (val));
  asm volatile ("l.nop %0": : "K" (NOP_EXIT));
  while(1);
}


//// putc() ////
#define NOP_PUTC 0x0004
void putc(volatile unsigned char c)
{
  asm volatile ("l.addi r3,%0,0": : "r" (c));
  asm volatile ("l.nop %0": : "K" (NOP_PUTC));
}


//// main() ////
int main()
{
  static const int test_vector[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 20, 21, 33, 66, 75, 80, 81, 90, 99, 100, 101, 1000, 10001, 1010101, 123456789, 1073741822, 1073741823, 2147483646, 2147483647};

  static const char bin2hex[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};

  volatile unsigned int x,y;
  volatile char n = '\n';
  volatile int res;

  for (y=0; y<33; y++) {
    for (x=1; x<33; x++) {
      res = test_vector[y]/test_vector[x];
      putc(bin2hex[(res>>28)&0xf]);
      putc(bin2hex[(res>>24)&0xf]);
      putc(bin2hex[(res>>20)&0xf]);
      putc(bin2hex[(res>>16)&0xf]);
      putc(bin2hex[(res>>12)&0xf]);
      putc(bin2hex[(res>> 8)&0xf]);
      putc(bin2hex[(res>> 4)&0xf]);
      putc(bin2hex[(res>> 0)&0xf]);
      putc(n);
    }
  }

  exit(0);
  return 0;
}

