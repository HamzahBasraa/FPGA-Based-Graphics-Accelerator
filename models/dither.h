/* ----------------------------------------------------------
**   
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module (header file)
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#ifndef DITHER_INC
#define DITHER_INC

#include "params.h"
#include "frameStore.h"

class DitherModule {
    public:
        void drawDither(int x0, int y0, int x1, int y1, int colour, FrameStore& fs);
};

#endif
