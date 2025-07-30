/* ----------------------------------------------------------
**   frameStore.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Frame store module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <frameStore.h>

using namespace std;

uint8_t FrameStore::read(int address) {
    if ((address < 0) || (address >= PIXELS*LINES))
    {
        cerr << "frameStore: WARNING - address "
                << address
                << " out of bounds in read."
                << endl;

        return -1;
    } 
    else {
        /* return the content of the frame store */
        return(membuf[address]);
    }
}

void FrameStore::write(int address, uint8_t colour) {
    if ((address < 0) || (address >= PIXELS*LINES))
        cerr << "frameStore: WARNING - address "
                << address
                << " out of bounds in write."
                << endl;
    else {
        /* write to the frame store and */
        /* handshake with the screen    */
        membuf[address] = colour;
        *handshake = 1;
    }
}
