/* ----------------------------------------------------------
**   virtualScreen.cpp
**
**   Algorithmic level model of Drawing engine
**
**   Virtual screen module
**
**   version 0.2  15/10/2007
**   contributors: lplana, jpepper, lbrackenbury
**
---------------------------------------------------------- */
#include <virtualScreen.h>

using namespace std;

VirtualScreen::VirtualScreen() {
    int i, j, k;

    /* temporarily establish the SIGCONT signal */
    /* handler to synchronise with the screen   */
    signal(SIGCONT, &scr_synch);
    /* establish the SIGCHLD signal     */
    /* handler to terminate with screen */
    signal(SIGCHLD, &scr_synch);

    /* bring up the screen in a child process */
    scrPid = fork();
    if (scrPid == -1) {
        cerr << "virtualScreen: ERROR - cannot start 'screen'" << endl;
        exit(1);
    }
    else if (scrPid == 0) {
        /* ------- the screen is the child process ------- */
        /* --- the screen updates from the frame store --- */
        nice(10); /* reduce priority of the screen process */
        if (execlp("vscreen", "vscreen", "-s1", "-k234", "-c332", NULL) < 0) {
            cerr << "virtualScreen: ERROR - cannot start 'vscreen'." << endl;
            exit(1);
        }
    }
    else {
        /* ------- the virtual screen is the parent process ------- */
        /* --- write to the frame store from the parent process --- */
        /* wait until the screen finishes setting up the shared buffer */
        /* the screen sends a SIGCONT signal to "wake up" this process */
        pause();
        /* attach to the shared memory buffer that is used as frame store */
        shm = setup_shm();
    }
}

VirtualScreen::~VirtualScreen() {
    int   status;
    if (CLOSESCR) {
        /* terminate the screen process */
        kill(scrPid, SIGTERM);
        waitpid(scrPid, &status, 0);
        /* release the shared memory buffer */
        release_shm();
    }
    else
        cout << "virtualScreen: remember to close the Virtual Screen" << endl;
}

uint8_t* VirtualScreen::shm_addr() {
    return(shm);
}

uint8_t* VirtualScreen::setup_shm() {
    key_t key;
    uint8_t *shm;

    key = 234; /* segment ID agreed with screen program            */
    /* locate the shared memory buffer that is used as frame store */
    if ((shmid = shmget(key, SHMSZ, 0666)) < 0) {
        cerr << "virtualScreen: ERROR - cannot locate shared memory." << endl;
        exit(1);
    }
    /* attach the segment to local data space */
    if ((shm = (uint8_t *) shmat(shmid, NULL, 0)) == (uint8_t *) -1) {
        cerr << "virtualScreen: ERROR - cannot attach shared memory." << endl;
        exit(1);
    }
    return (shm);
}

void VirtualScreen::release_shm() {
    /* release the shared memory buffer that is used as frame store  */
    if (shmctl(shmid, IPC_RMID, NULL) < 0) {
        cerr << "virtualScreen: ERROR - cannot release shared memory." << endl;
        exit(1);
    }
}

void VirtualScreen::scr_synch (int sigNum) {
    signal(SIGCONT, SIG_DFL);
    if (sigNum == SIGCONT) {
        /* once the screen has sent the SIGCONT signal we can */
        /* restore the signal handling to its default         */
        signal(SIGCONT, SIG_DFL);
    }
    else if (sigNum == SIGCHLD) {
        /* screen was closed -> terminate */
        exit(0);
    }
}
