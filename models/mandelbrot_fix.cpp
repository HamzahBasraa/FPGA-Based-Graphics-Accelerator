/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: Mandelbrot: fixed point
**
**   version 0.3  10/2/2015
**   contributors: lplana, jpepper, lbrackenbury, jgarside
**
---------------------------------------------------------- */
#include <mandelbrot.h>
#include <stdio.h>
#include <math.h>

// Default covers whole screen - reduce for smaller areas
#define XSIZE    PIXELS
#define YSIZE    LINES
#define B_PLACES 24		// Number of places after binary point

void MandelbrotModule::drawMandelbrot(double x_in, double y_in, double inc_in,
                                      int max_iter, FrameStore& fs)
{
 int address;			// Screen pixel address
 int line_count;		// Loop control/screen coordinates
 int pixel_count;
 int32_t x_start;		// 'Fractional' LHS of window
 int32_t x;
 int32_t y;
 int32_t inc;
 int64_t zr;			// Components of complex multiplication
 int64_t zi;			//  which are twice the length of inputs
 int64_t zr_new;		// Temporary variable during calculation
 int64_t modulus_sq;		// Square of the modulus
 int iterations;		// Iteration count; later colour

 x_in = x_in*pow(2, B_PLACES);	// Fixed point conversions
 y_in = y_in*pow(2, B_PLACES);	// Multiply by 2^B_PLACES
 inc_in = inc_in*pow(2, B_PLACES);
 x = (int32_t)x_in;		//  and move to fixed point representation
 y = (int32_t)y_in;
 inc = (int32_t)inc_in;

 x_start = x;			// Remember coordinate of LHS

 // Iterative loop over chosen area
  for (line_count = 0; line_count < YSIZE; ++line_count)
  {   
   for (pixel_count = 0; pixel_count < XSIZE; ++pixel_count)
   {
    iterations = 0;
    zr = 0;
    zi = 0;
    modulus_sq = 0;		// Needs to enter 'while' loop

    // Iterate until modulus 'infinite' or maximum reached
    // Remember: (a + ib)^2 = (a*a - b*b) + i(2ab)
    while ((modulus_sq < 4) && (iterations < max_iter))
    {	// Note: some multiplications are -duplicated- below
     modulus_sq = (zr*zr + zi*zi) >> (2*B_PLACES);
     zr_new = ((zr*zr) >> B_PLACES) - ((zi*zi) >> B_PLACES) + x;
     zi = ((zr*zi) >> B_PLACES)*2 + y;
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


















