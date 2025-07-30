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
#ifndef RECTANGLE_INC
#define RECTANGLE_INC

#include "params.h"
#include "frameStore.h"

class RectangleModule {
    public:
        void drawRectangle(int x0, int y0, int x1, int y1, int colour, FrameStore& fs);
};

#endif
