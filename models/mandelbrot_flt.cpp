/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: Mandelbrot: floating point
**
**   version 0.3  10/2/2015
**   contributors: lplana, jpepper, lbrackenbury, jgarside
**
---------------------------------------------------------- */
#include <mandelbrot.h>
#include <stdio.h>
#include <math.h>

// Default covers whole screen - reduce for smaller areas
#define XSIZE PIXELS
#define YSIZE LINES

void MandelbrotModule::drawMandelbrot(double x, double y, double inc,
                                      int max_iter, FrameStore& fs)
{
 int address;			// Screen pixel address
 int line_count;		// Loop control/screen coordinates
 int pixel_count;
 double x_start;		// 'Fractional' LHS of window
 double zr;			// Components of complex multiplication
 double zi;			//  which are twice the length of inputs
 double zr_new;			// Temporary variable during calculation
 double modulus_sq;		// Square of the modulus
 int iterations;		// Iteration count; later colour

 x_start = x;			// Remember coordinate of LHS

 // Iterative loop over chosen area
  for (line_count = 0; line_count < YSIZE; ++line_count)
  {   
   for (pixel_count = 0; pixel_count < XSIZE; ++pixel_count)
   {
    iterations = 0;
    zr = 0.0;
    zi = 0.0;
    modulus_sq = 0.0;		// Needs to enter 'while' loop

    // Iterate until modulus 'infinite' or maximum reached
    // Remember: (a + ib)^2 = (a*a - b*b) + i(2ab)
    while ((modulus_sq < 4.0) && (iterations < max_iter))
    {	// Note: some multiplications are -duplicated- below
     modulus_sq = zr*zr + zi*zi;
     zr_new = (zr*zr - zi*zi) + x;
     zi = zr*zi*2 + y;
     zr = zr_new;
     iterations++;
    }

    address = (PIXELS * line_count) + pixel_count;
    fs.write(address, (iterations));	// Plot point
    x = x + inc;		// Move coordinate right
   }
   y = y + inc;			// Move coordinate down
   x = x_start;			//  and to start of new row
  }
}


















