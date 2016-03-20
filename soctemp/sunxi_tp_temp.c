/******************************
            soctemp

This is basically "sunxi_tp_temp" from
http://forum.lemaker.org/forum.php?mod=viewthread&tid=8137&page=3#pid47437

Thank you "FPeter"!
*******************************/
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include "mod_mmio.h"

int main(int argc, char **argv)
{

  int opt ;
  int unit = 0 ;
  int debug = 0 ;
  int adj = 1447 ;

//  if ( argc>1 )
//    adj = atoi(argv[1]) ;

  while ((opt = getopt(argc, argv, "cCfFkKdD")) > 0)
  {
    switch (opt)
    {
      case 'f':
        unit = 1 ;
        break ;
      case 'F':
        unit = 1 ;
        break ;
      case 'k':
        unit = 2 ;
        break ;
      case 'K':
        unit = 2 ;
        break ;
      case 'd':
        debug = 1 ;
        break ;
      case 'D':
        debug = 1 ;
        break ;
    }
  }

  mmio_write(0x01c25000, 0x0027003f) ;
  mmio_write(0x01c25010, 0x00040000) ;
  mmio_write(0x01c25018, 0x00010fff) ;
  mmio_write(0x01c25004, 0x00000090) ;

  if ( debug == 1 )
  {
    printf("w 0x01c25000: %08lx\n", mmio_read(0x01c25000)) ;
    printf("w 0x01c25010: %08lx\n", mmio_read(0x01c25010)) ;
    printf("w 0x01c25018: %08lx\n", mmio_read(0x01c25018)) ;
    printf("w 0x01c25004: %08lx\n", mmio_read(0x01c25004)) ;
    printf("r 0x01c25020: %08lx\n", mmio_read(0x01c25020)) ;
  }

  switch (unit)
  {
    case 0:
      printf("%0.1f",(float)(mmio_read(0x01c25020)-adj)/10) ;
        printf(" °C") ;
      break ;
    case 1:
      printf("%0.1f",((float)(mmio_read(0x01c25020)-adj)/10*9/5)+32) ;
        printf(" °F") ;
      break ;
    case 2:
      printf("%0.2f",(float)(mmio_read(0x01c25020)-adj)/10+273.15) ;
        printf(" K") ;
      break ;
  }

  printf("\n");

  return 0;

}
