GPP=g++
CFLAGS= -I. -O0
LDFLAGS= -Wall
OBJ_FILES= point.o line.o circle.o character.o rectangle.o mandelbrot.o automaton.o dither.o sobel.o frameStore.o commandInt.o main.o virtualScreen.o

.cpp.o:
	$(GPP) $(CFLAGS) -c $<

controller: $(OBJ_FILES)
	$(GPP) $(OBJ_FILES) $(LDFLAGS) -o $@

*.o: params.h

tidy:
	rm -f *~ *.o *.bak core* tags

clean: tidy
	rm -f controller fsDump.txt screenDump.png
