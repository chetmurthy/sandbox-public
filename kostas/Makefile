
CFLAGS=--std=gnu++11 -O6

all: ex1 unboxed-ex1 ex2 unboxed-ex2 read1 unboxed-read1

ex1: ex1.cpp
	g++ $(CFLAGS) -o ex1 ex1.cpp

unboxed-ex1: ex1.cpp
	g++ $(CFLAGS) -DUNBOXED -o unboxed-ex1 ex1.cpp

ex2: ex2.cpp
	g++ $(CFLAGS) -o ex2 ex2.cpp

unboxed-ex2: ex2.cpp
	g++ $(CFLAGS) -DUNBOXED -o unboxed-ex2 ex2.cpp

read1: read1.cpp
	g++ $(CFLAGS) -o read1 read1.cpp

unboxed-read1: read1.cpp
	g++ $(CFLAGS) -DUNBOXED -o unboxed-read1 read1.cpp

clean:
	rm -f ex? read1 unboxed-ex? unboxed-read1
