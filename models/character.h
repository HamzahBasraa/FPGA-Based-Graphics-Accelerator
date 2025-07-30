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
#ifndef CHARACTER_INC
#define CHARACTER_INC

#define CHAR_HEIGHT 12
#define ROM_SIZE CHAR_HEIGHT*128

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <string>

#include "params.h"
#include "frameStore.h"

class CharacterModule {

    private:
        char char_rom[ROM_SIZE];

    public:
        CharacterModule();
        void drawCharacter(int x, int y, int char_adr, uint8_t colour, FrameStore& fs);
};

#endif
