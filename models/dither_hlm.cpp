/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: dithering
**                          high-level model
**   This model uses a 2D array to accumulate the corrections
**   to each pixel separately.  This serves to help 'explain'
**   the algorithm.  It is not a good model for implementation
**   because this requires more storage than the real frame
**   store, as the fractional values require more bits and
**   there is one variable per colour per pixel.
**   Also note that the actual values of a given pixel
**   achieved may vary according to where rounding/truncation
**   takes place, so this may not (without modification)
**   produce exactly the same pattern as the 'simplest'
**   hardware model.
**   The final *exact* pattern is not important as long as
**   the correct visual effect is achieved.
**
**   version 0.3  12/2/2015
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <dither.h>
#include <stdio.h>


void DitherModule::drawDither(int x0, int y0, int x1, int y1, int colour, FrameStore& fs)
{
// Draws a dithered rectangle x0,y0 x1,y1 //
// Takes a 24-bit colour pixel and dithers it to 8-bit colour (rrrgggbb) //

int red_frame [PIXELS] [LINES];
int green_frame [PIXELS] [LINES];
int blue_frame [PIXELS] [LINES];

int x, y;
int red, green, blue;	// 8-bit colours
int   red_pixel,   red_nearest,   red_diff;
int green_pixel, green_nearest, green_diff;
int  blue_pixel,  blue_nearest,  blue_diff;
int rrrgggbb;

// Extract colour components from input
red =   ((colour & 0xff0000) >> 16);
green = ((colour & 0x00ff00) >> 8);
blue =    colour & 0x0000ff;

// Make a map of colour 'corrections' for each pixel
for (x = 0; x < PIXELS; x++)
  for (y = 0; y < LINES; y++)
   {
    red_frame[x][y]   = 0;
    green_frame[x][y] = 0;
    blue_frame[x][y]  = 0;
   }

for (y = y0; y <= y1; y++)	// Over some chosen area ...
  for (x = x0; x <= x1; x++)
    {
    // Establish current pixel hue (with correction) and what can be plotted
    red_pixel = red + (red_frame[x][y] >> 4);	// Desired amount of red colour
    if (red_pixel > 0xFF) red_pixel = 0xFF;	// Max pixel value
    red_nearest = (red_pixel + 0x10) & 0xE0;	// Best approximation, round to 3 bits
    red_diff = red_pixel - red_nearest;		// Difference of 'plotted' from 'desired'

    green_pixel = green + (green_frame[x][y] >> 4);// Desired amount of green colour
    if (green_pixel > 0xFF) green_pixel = 0xFF; // Max pixel value
    green_nearest = (green_pixel + 0x10) & 0xE0;// Best approximation, round to 3 bits
    green_diff = green_pixel - green_nearest;	// Difference of 'plotted' from 'desired'

    blue_pixel = blue + (blue_frame[x][y] >> 4);// Desired amount of blue colour
    if (blue_pixel > 0xFF) blue_pixel = 0xFF;	// Max pixel value
    blue_nearest = (blue_pixel + 0x20) & 0xC0;	// Approximation, round to 2 bits
    blue_diff = blue_pixel - blue_nearest;	// Difference of 'plotted' from 'desired'

    /* Strictly, the blue encoding represents equivalent values of:
       {0xE0, 0xA0, 0x60, 0x00} but this is rather more work to calculate. */

    if (x < x1)					// Except for last column ...
      {						// Calculate and save pixel x+1,y pixel
      red_frame[x+1][y]   += 7*red_diff;
      green_frame[x+1][y] += 7*green_diff;
      blue_frame[x+1][y]  += 7*blue_diff;
      if (y < y1)				// Except for last row ...
       {					// Calculate and save pixel x+1,y+1 pixel
        red_frame[x+1][y+1]   += 1*red_diff;
        green_frame[x+1][y+1] += 1*green_diff;
        blue_frame[x+1][y+1]  += 1*blue_diff;
       }
      }
    if (y < y1)					// Except for last row ...
     {						// Calculate and save pixel x,y+1 pixel
      red_frame[x][y+1]   += 5*red_diff;
      green_frame[x][y+1] += 5*green_diff;
      blue_frame[x][y+1]  += 5*blue_diff;
      if (x != x0)		       		// Except for last column ...
       {					// Calculate and save pixel x-1,y+1 pixel
        red_frame[x-1][y+1]   += 3*red_diff;
        green_frame[x-1][y+1] += 3*green_diff;
        blue_frame[x-1][y+1]  += 3*blue_diff;
       }
      }

   // Set to framestore colour map
   rrrgggbb = red_nearest + (green_nearest>>3) + (blue_nearest>>6);
   fs.write((y*PIXELS +x), rrrgggbb);		// Write RGB to framestore
   }
  
/* You might, for example, use this to view the 'corrections', afterwards

for (x = x0; x <= x1; x++)
  for (y = y0; y <= y1; y++)
   {
     printf("%5d   %5d   %5d   %5d   %5d\n", x, y, red_frame[x][y],
                               green_frame[x][y], blue_frame[x][y]);
   }

*/

}
