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
#ifndef MANDELBOT_INC
#define MANDELBOT_INC

#include "params.h"
#include "frameStore.h"

class MandelbrotModule {
    public:
        void drawMandelbrot(double a, double b, double inc, int max_iter, FrameStore& fs);
};

#endif
