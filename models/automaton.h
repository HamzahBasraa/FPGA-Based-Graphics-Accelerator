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
#ifndef AUTOMATON_INC
#define AUTOMATON_INC

#include "params.h"
#include "frameStore.h"

class AutomatonModule {
    public:
        void drawAutomaton(uint8_t colour, FrameStore& fs);
};

#endif
