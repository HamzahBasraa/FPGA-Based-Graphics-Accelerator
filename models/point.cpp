/* ----------------------------------------------------------
**   drawingEngine.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <point.h>
#include <stdio.h>


void PointModule::drawPoint(int x, int y, uint8_t colour, FrameStore& fs) {
    /* write pixel to frame store */
    fs.write(PIXELS*y+x, colour);
}



















