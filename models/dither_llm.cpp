/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: dithering
**                          high-level model
**   This model uses a 1D array to accumulate the corrections
**   to each pixel across a line, reusing this buffer in
**   subsequent scans.  This is a suitable model for
**   implementation because it limits the temporary storage
**   used which can then be placed on the FPGA (and dual-
**   ported).
**   Note that the actual values of a given pixel achieved
**   may vary according to where rounding/truncation takes
**   place, so this may not (without modification) produce
**   exactly the same pattern as the 'simplest' hardware
**   model.
**   The final *exact* pattern is not important as long as
**   the correct visual effect is achieved.
**
**   version 0.3  12/2/2015
**   contributors: jpepper, jgarside
**
---------------------------------------------------------- */
#include <dither.h>
#include <stdio.h>


void DitherModule::drawDither(int x0, int y0, int x1, int y1,
                              int colour, FrameStore& fs)
{
// Draws a dithered rectangle x0,y0 x1,y1 //
// Takes a 24-bit colour pixel and dithers it to 8-bit colour (rrrgggbb) //

int   red_line [PIXELS];
int green_line [PIXELS];
int  blue_line [PIXELS];

int x, y;
int red, green, blue;	// 8-bit colours

int   red_pixel,   red_nearest,   red_diff;
int green_pixel, green_nearest, green_diff;
int  blue_pixel,  blue_nearest,  blue_diff;
int rrrgggbb;

int red_bb, green_bb, blue_bb;		// Previous 'diff's
int red_cc, green_cc, blue_cc;		// Partially accumulated 'diff's

// Extract colour components from input
red =   ((colour & 0xff0000) >> 16);
green = ((colour & 0x00ff00) >> 8);
blue =    colour & 0x0000ff;

// Initialising the buffer is 'cleaner' in software; how about in hardware?
for (x = x0; x <= x1; x++)
  {
  red_line[x]   = 0;
  green_line[x] = 0;
  blue_line[x]  = 0;
  }

for (y = y0; y <= y1; y++)	// Over some chosen area ...
  {
  red_bb   = 0;			// Initialise correction at row start
  green_bb = 0;
  blue_bb  = 0;

  for (x = x0; x <= x1; x++)
    {
    // Establish current pixel hue (with correction) and what can be plotted
    red_pixel = red + ((red_line[x] + 7*red_bb)>>4);// Desired red intensity
    if (red_pixel > 0xFF) red_pixel = 0xFF;	// Max. pixel value
    red_nearest = (red_pixel + 0x10) & 0xE0;	// Best approximation, round to 3 bits
    red_diff = red_pixel - red_nearest;		// Difference of 'plotted' from 'desired'

    green_pixel = green + ((green_line[x] + 7*green_bb)>>4);// Desired green intensity
    if (green_pixel > 0xFF) green_pixel = 0xFF; // Max. pixel value
    green_nearest = (green_pixel + 0x10) & 0xE0;// Best approximation, round to 3 bits
    green_diff = green_pixel - green_nearest;	// Difference of 'plotted' from 'desired'

    blue_pixel = blue + ((blue_line[x] + 7*blue_bb)>>4);// Desired blue intensity
    if (blue_pixel > 0xFF) blue_pixel = 0xFF;	// Max. pixel value
    blue_nearest = (blue_pixel + 0x20) & 0xC0;	// Approximation, round to 2 bits
    blue_diff = blue_pixel - blue_nearest;	// Difference of 'plotted' from 'desired'

    /* Strictly, the blue encoding represents equivalent values of:
       {0xE0, 0xA0, 0x60, 0x00} but this is rather more work to calculate. */

    // Accumulate corrections for subsequent row.
    // Division of *_diff deferred until they're about to be used.

    if (x > x0)				// Except for first column ...
      {					// ... save previous accumulated correction
      red_line[x-1]   = red_cc   + 3*red_diff;
      green_line[x-1] = green_cc + 3*green_diff;
      blue_line[x-1]  = blue_cc  + 3*blue_diff;
      }

    red_cc   = red_bb   + 5*red_diff;	// Below current pixel
    green_cc = green_bb + 5*green_diff;
    blue_cc  = blue_bb  + 5*blue_diff;

    red_bb   = red_diff;		// Below-right of current pixel
    green_bb = green_diff;
    blue_bb  = blue_diff;

    if (x == x1)			// In the last column ...
      {					// ... also save accumulated correction
      red_line[x]   = red_cc;
      green_line[x] = green_cc;
      blue_line[x]  = blue_cc;
      }

   // Set to framestore colour map
   rrrgggbb = red_nearest + (green_nearest>>3) + (blue_nearest>>6);
   fs.write((y*PIXELS +x), rrrgggbb);		// Write RGB to framestore
   }
  }
}
