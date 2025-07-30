/* ----------------------------------------------------------
**   drawingEngine.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Drawing engine module: Character plotting
**
**   version 0.3  11/2/2015
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <character.h>  

// Read character set into a look-up table.
// Each character is 8-bits wide with 1 bit indicating a
// foreground pixel.  Characters are CHAR_HEIGHT bytes high.

CharacterModule::CharacterModule() 
 {
  using namespace std;
  ifstream char_file;
  string char_str;
  int  rom_w_adr=0;

  char_file.open("characters.hex");
  while (getline(char_file, char_str))
   {
    if(rom_w_adr <= ROM_SIZE)
     {
      char_rom[rom_w_adr] = (char)strtol(char_str.c_str(), NULL, 16);
      rom_w_adr++; 
     }    
   }
  char_file.close();
 }


// There is plenty of opportunities to enhance this,
// e.g. by scaling of changing the orientation ...

void CharacterModule::drawCharacter(int x, int y, int char_No,
                                    uint8_t colour, FrameStore& fs)
 {
  unsigned char char_row;	// Index into generator ROM
  int char_column_index;
  int char_row_index;
  unsigned char pixel_mask;	// Bit mask used to extract pixel

  // Iterate over the area of a character: horizontally ...
  for (char_row_index = 0; char_row_index < CHAR_HEIGHT; char_row_index++)
   {
    char_row = char_rom[(char_No*CHAR_HEIGHT)+char_row_index];
    pixel_mask = 0x01;
    for (char_column_index = 0; char_column_index < 8; char_column_index++)   
     {
      if ((char_row & pixel_mask) != 0)	// See below *
       fs.write((PIXELS*(y+char_row_index))+x+char_column_index, colour);
//    else
//     write background colour if desired
      pixel_mask = pixel_mask << 1;
     } 
   }
 }

// * There's a lot of arithmentic in the address calculation.
//   This can be reduced by keeping an address pointer.
