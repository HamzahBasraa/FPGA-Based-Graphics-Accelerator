/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: 1D cellular automaton
**                          using frame store read-back
**   This reads back the cell values as pixels (0 or not)
**   from the line above the current drawing.  It relies on
**   the first pixel line being initialised before execution.
**
**   version 0.3  11/2/2015
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <automaton.h>
#include <cstdint>
#include <stdio.h> 

#define GENERATIONS (LINES-1)

void AutomatonModule::drawAutomaton(uint8_t colour, FrameStore& fs)
{
			// Rule here is -not- passed as argument
 char rule[8] = {0,1,1,1,1,0,0,0};  /*Rule 30*/
 int rd_address;
 int wr_address;
 int line_count;
 int pixel_count;
 char L, me, R;		// binary (previous) states of 3 cells
 char key;

  for (line_count = 0; line_count < GENERATIONS; ++line_count)
  {     // Iterate over a set of lines from top of screen
   for (pixel_count = 0; pixel_count < PIXELS; ++pixel_count)
   {    // Iterate over a line of the screen
    rd_address = pixel_count + PIXELS*line_count;
    if (pixel_count == 0)
     {  // First pixel?  Worry about LH margin
      L  = 0;
      me = fs.read(rd_address);
      R  = fs.read(rd_address+1);
     }
    else if (pixel_count == (PIXELS-1))
     {  // Last pixel?  Worry about RH margin
      L  = me;
      me = R;
      R  = 0;
     }
    else
     {  // else just shift from previous states
      L  = me;
      me = R;
      R  = fs.read(rd_address+1);
     }
    if (L  != 0) L  = 1;	// Assemble a key from states
    if (me != 0) me = 1;
    if (R  != 0) R  = 1;
    key = (L<<2) + (me<<1) + R;

    wr_address = pixel_count + PIXELS*(line_count+1);
			// Writing is the line below reading
    if(rule[key] == 1)
     fs.write(wr_address, colour);
//  else		// Not needed if screen already blanked
//   fs.write(wr_address, 0);
   }
  }
}
