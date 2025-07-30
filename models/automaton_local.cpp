/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: 1D cellular automaton
**                          using local state store
**   This uses a local Boolean array to hold cell state.
**   Initialisation is internal.
**
**   version 0.3  11/2/2015
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <automaton.h>
#include <stdio.h>

//#define BLACK        0
#define GENERATIONS (LINES-1)

void AutomatonModule::drawAutomaton(uint8_t colour, FrameStore& fs)
{
			// Rule here is -not- passed as argument
 char rule[8] = {0,1,1,1,1,0,0,0};  /*Rule 30*/
 int  cell[PIXELS];	// Really Boolean array
 int  old;		// Cell state from previous iteration
 int  wr_address;
 int  line_count;
 int  pixel_count;
 char L, me, R;		// binary (previous) states of 3 cells
 char key;

  // Initialise cell state
  for (pixel_count = 0; pixel_count < PIXELS; ++pixel_count)
   cell[pixel_count] = 0;

  cell[PIXELS/2] = 1;	// Seed at centre cell
  // Note: doesn't update screen top line

  for (line_count = 1; line_count < GENERATIONS; ++line_count)
  {     // Iterate over a set of lines from (near) top of screen
        // (Begins at '1' to retain similarity with alternative model)
   old = 0;
   for (pixel_count = 0; pixel_count < PIXELS; ++pixel_count)
   {    // Iterate over a line of the screen
     if (pixel_count == 0) L = 0;
     else                  L = cell[pixel_count-1];
     me = cell[pixel_count];
     if (pixel_count == (PIXELS-1)) R = 0;
     else                           R = cell[pixel_count+1];

    if (L  != 0) L  = 1;	// Assemble a key from states
    if (me != 0) me = 1;
    if (R  != 0) R  = 1;
    key = (L<<2) + (me<<1) + R;

    wr_address = pixel_count + PIXELS*line_count;

    cell[pixel_count-1] = old;	// Update after 'L' read

    if (rule[key] == 1)
     {
     fs.write(wr_address, colour);
     old = 1;
     }
    else
     {
     fs.write(wr_address, BLACK);
     old = 0;
     }
   }
  }
}
