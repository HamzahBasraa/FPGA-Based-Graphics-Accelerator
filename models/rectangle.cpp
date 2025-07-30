/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: Rectangle (plus)
**
**   version 0.3  11/2/2015
**   contributors: lplana, jpepper, lbrackenbury, jgarside
**
---------------------------------------------------------- */
#include <rectangle.h>
#include <stdio.h>

// This model DOES NOT access multiple pixels in each frame
// store cycle.  That needs adding to the Verilog model.

void RectangleModule::drawRectangle(int x0, int y0, int x1, int y1,
                                    int colour, FrameStore& fs)
{
 int address;
 int line_count;
 int pixel_count;
 uint8_t colour_and, colour_xor;	// Packed into one argument

  colour_and = (colour >> 8) & 0xFF;
  colour_xor = colour & 0xFF;

  for (line_count = y0; line_count < y1; ++line_count)
  {   
   for (pixel_count = x0; pixel_count < x1; ++pixel_count)
   {
    address = pixel_count + PIXELS*line_count;
/*
    // This only colours black pixels within the rectangle (example)
    if (fs.read(address) == BLACK)
     fs.write(address, colour);
*/
    // This can write, XOR etc. the colour to the display.
    fs.write(address, (fs.read(address) & colour_and) ^ colour_xor);
    // Could also try combining with textures or moving areas
    // i.e. 'blitting'.
   }
  }
}
