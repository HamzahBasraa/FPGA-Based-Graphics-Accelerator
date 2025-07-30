/* ----------------------------------------------------------
**   virtualScreen.h
**
**   Algorithmic level model of Drawing engine
**
**   Virtual screen module (header file)
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#ifndef VSINC
#define VSINC

#include <cstdlib>
#include <cstdint>
#include <unistd.h>
#include <sys/shm.h>
#include <signal.h>
#include <sys/wait.h>
#include <iostream>

#include "params.h"

class VirtualScreen {
    private:
        /* pointer to the shared memory used by other */
        /* processes to communicate with the screen   */
        uint8_t *shm;
        int   shmid;
        uint8_t* setup_shm();
        void  release_shm();
        pid_t scrPid;

        static void scr_synch (int sigNum);

    public:
        /* returns the pointer of the shared memory block */
        uint8_t* shm_addr();

        /* the constructor brings up the virtual screen */
        VirtualScreen();

        /* the destructor can close the virtual screen  */
        ~VirtualScreen();
};

#endif
