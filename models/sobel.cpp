/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Sobel filter module:
**
**   This model is a simple, unoptimised Sobel filter using
**   the lop-left quarter of the display as input and the
**   top-right quarter as output.
**
**   version 0.1  8/9/2015
**   contributors: lplana, jpepper, lbrackenbury, jgarside
**
---------------------------------------------------------- */
#include <sobel.h>
#include <stdio.h>


void SobelModule::filter(int threshold, FrameStore& fs)
{
  int i, q;
  int x, y;
  int address, pixel;
  int acc_v_r, acc_v_g, acc_v_b;
  int acc_h_r, acc_h_g, acc_h_b;
  int rrr, ggg, bb;

  /* For simplicity, this leaves a 1 pixel margin around the scanned area */
  for (y = 1; y < 238; y++)
    for (x = 1; x < 318; x++)
      {
        acc_v_r = 0;
        acc_v_g = 0;
        acc_v_b = 0;
        acc_h_r = 0;
        acc_h_g = 0;
        acc_h_b = 0;

        for (i = 0; i < 8; i++)
          {
            address = y*PIXELS + x;
            switch (i)
              {
              case 0: pixel = fs.read(address - 640 - 1); break;
              case 1: pixel = fs.read(address - 640    ); break;
              case 2: pixel = fs.read(address - 640 + 1); break;
              case 3: pixel = fs.read(address       - 1); break;
              case 4: pixel = fs.read(address       + 1); break;
              case 5: pixel = fs.read(address + 640 - 1); break;
              case 6: pixel = fs.read(address + 640    ); break;
              case 7: pixel = fs.read(address + 640 + 1); break;
              }

            rrr = (pixel >> 5) & 7;
            ggg = (pixel >> 2) & 7;
            bb  = (pixel << 1) & 6;        // Blue shifted up to same significance as red & green

            switch (i)
              {
              case 0: acc_v_r -= rrr;
                      acc_v_g -= ggg;
                      acc_v_b -= bb;
                      acc_h_r -= rrr;
                      acc_h_g -= ggg;
                      acc_h_b -= bb;
                      break;
              case 1: acc_h_r -= rrr << 1;
                      acc_h_g -= ggg << 1;
                      acc_h_b -= bb  << 1;
                      break;
              case 2: acc_v_r += rrr;
                      acc_v_g += ggg;
                      acc_v_b += bb;
                      acc_h_r -= rrr;
                      acc_h_g -= ggg;
                      acc_h_b -= bb;
                      break;
              case 3: acc_v_r -= rrr <<1;
                      acc_v_g -= ggg <<1;
                      acc_v_b -= bb <<1;
                      break;
              case 4: acc_v_r += rrr << 1;
                      acc_v_g += ggg << 1;
                      acc_v_b += bb  << 1;
                      break;
              case 5: acc_v_r -= rrr;
                      acc_v_g -= ggg;
                      acc_v_b -= bb;
                      acc_h_r += rrr;
                      acc_h_g += ggg;
                      acc_h_b += bb;
                      break;
              case 6: acc_h_r += rrr <<1;
                      acc_h_g += ggg <<1;
                      acc_h_b += bb <<1;
                      break;
              case 7: acc_v_r += rrr;
                      acc_v_g += ggg;
                      acc_v_b += bb;
                      acc_h_r += rrr;
                      acc_h_g += ggg;
                      acc_h_b += bb;
                      break;
              }
          }
        q = abs(acc_v_r) + abs(acc_v_g) + abs(acc_v_b) + abs(acc_h_r)
                         + abs(acc_h_g) + abs(acc_h_b);
        if (q > threshold) q = 255; else q = 0;
        fs.write(address + 320, q);
      }

}
