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
#ifndef SOBEL_INC
#define SOBEL_INC

#include "params.h"
#include "frameStore.h"

class SobelModule {
    public:
       void filter(int threshold, FrameStore& fs);
};

#endif
