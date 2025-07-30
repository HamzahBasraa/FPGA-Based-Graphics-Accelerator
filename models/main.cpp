/* ----------------------------------------------------------
**   main.cpp
**
**   Algorithmic level model of Drawing engine
**
**   TOP LEVEL module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <cstdlib>

#include "params.h"
#include "commandInt.h"
#include "virtualScreen.h"
#include "frameStore.h"
#include "point.h"
#include "line.h"
#include "circle.h"
#include "character.h"
#include "rectangle.h"
#include "mandelbrot.h"
#include "automaton.h"
#include "dither.h"
#include "sobel.h"

int main () {

    CommandInt    ci;
    VirtualScreen vs;
    FrameStore    fs(vs.shm_addr());


    /* Drawing modules */
       PointModule point;
       LineModule line;
       CircleModule circle;
       CharacterModule character;
       RectangleModule rectangle;
       MandelbrotModule mandelbrot;
       AutomatonModule automaton;
       DitherModule dither;
       SobelModule sobel;


    Command command;
    int     getNewCmd = true;

    do {
        command = ci.readCmd();
        switch (command.type) {
            case Point:
                point.drawPoint(command.param[0], /* start point x coord. */
                        command.param[1], /* start point y coord. */
                        command.param[2], /* colour               */
                        fs);
                break;
            case Line:
                line.drawLine(command.param[0], /* start point x coord. */
                        command.param[1], /* start point y coord. */
                        command.param[2], /* end point x coord.   */
                        command.param[3], /* end point y coord.   */
                        command.param[4], /* colour               */
                        fs);
                break;
            case Circle:
                circle.drawCircle(command.param[0], /* centre point x coord. */
                        command.param[1], /* centre point y coord. */
                        command.param[2], /* radius.		   */
                        command.param[3], /* colour                */
                        fs);
                break;
            case Character:
                character.drawCharacter(command.param[0], /* x coord top of character */
                        command.param[1], /*  y coord left of character */
                        command.param[2], /*  rom address of character		   */
                        command.param[3], /* colour                */
                        fs);
                break;
            case Rectangle:
                rectangle.drawRectangle(command.param[0], /* start point x coord. */
                        command.param[1], /* start point y coord. */
                        command.param[2], /* end point x coord.   */
                        command.param[3], /* end point y coord.   */
                        command.param[4], /* colour               */
                        fs);
                break;
            case Mandelbrot:
                mandelbrot.drawMandelbrot(command.param[0], /* a0 */
                        command.param[1], /* b0 */
                        command.param[2], /* step size   */
                        command.param[3], /* max number of interations   */
                        fs);
                break;
            case Automaton:
                automaton.drawAutomaton(command.param[0], /* colour */
                        fs);
                break;
            case Dither:
                dither.drawDither(command.param[0], /* start point x coord. */
                        command.param[1], /* start point y coord. */
                        command.param[2], /* end point x coord.   */
                        command.param[3], /* end point y coord.   */
                        command.param[4], /* colour               */
                        fs);
                break;
            case Sobel:
                sobel.filter(command.param[0],       /* threshold */
                             fs);
                break;
            case Clear:
                /* clear the screen by drawing BLACK horizontal lines */
                ci.clearScreen(fs);
                break;
            case Dump:
                ci.dump(vs.shm_addr());
                break;
            case Sleep:
                sleep(command.param[0]); /* time to sleep in s  */
                break;
            case Quit:
                getNewCmd = false; /* stop processing commands  */
                break;
            case Unknown:
                break; /* ignore unknown command */
        }
    } while (getNewCmd);
}
