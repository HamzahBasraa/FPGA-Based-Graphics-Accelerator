/* ----------------------------------------------------------
**   drawingEngine.h
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module (header file)
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#ifndef POINT_INC
#define POINT_INC

#include "params.h"
#include "frameStore.h"

class PointModule {
    public:
        void drawPoint(int x, int y, uint8_t colour, FrameStore& fs);
};

#endif
